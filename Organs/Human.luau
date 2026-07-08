local Signal = require("@self/Signal")

local Types = require("@self/Types")
type Signal<T...> = Signal.Signal<T...>

local Organ = require("@self/Organ")

local Human = {} :: Types.Human
Humand.__index = Human

-- Helpers --
local organListMetatable = {
    __index = function(self, key)
        local target = rawget(self, key)

        if typeof(target) == "table" then
            return target[1], target
        end

        return target
    end
}

local function validateCharacter(char: Model): boolean
    if not char:IsA("Model") then
        return false
    end

    if not char:FindFirstChild("HumanoidRootPart") then
        return false
    end

    if not char:FindFirstChild("Humanoid") then
        return false
    end

    return true
end

local function getLimb(char: Model, limb: Types.Limb | BasePart): BasePart?
    if typeof(limb) == "Instance" and limb:IsA("BasePart") then
        return limb
    end

    local part = char:FindFirstChild(limb)

    if part and part:IsA("BasePart") then
        return part
    end

    return nil
end

local function calculateIntegrity(curr: number, max: number): number
    if max == 0 then
        return 1
    end

    return curr/max
end

-- Reset Function --
function Human:Reset()
    for _, organ in self.Organs do
        organ:Repair()
    end
end

-- Attaching and Removing Organs --
function Human:AttachOrgan(organ: Types.Organ, adornee: BasePart, offset: CFrame?)
    if not adornee or not adornee:IsA("BasePart") then
        warn(`[Organs.Human]: Failed to attach organ {organ.Name} to {self.Character and self.Character.Name or "Unknown"} because adornee is invalid`)
        return
    end

    -- Adding the Organ in the object
    organ.Owner = self

    local indexCheck = self[organ.Name]
    if indexCheck then
        warn(`[Organs.Human]: It is not suggested to have identically named Organs on the same Human (Name: {organ.Name}, Human: {self.Character and self.Character.Name or "Unknown"})`)
        if typeof(indexCheck) == "table" then
            table.insert(indexCheck, organ)
        else
            self[organ.Name] = {indexCheck, organ}
        end
    else
        self[organ.Name] = organ
    end

    -- Handling integrity change
    local pastIntegrity = self.Integrity

    self._maxIntegrity += organ.IntegrityWeight or 0
    self._currIntegrity += organ.Integrity * organ.IntegrityWeight

    self.Integrity = calculateIntegrity(self._maxIntegrity, self._currIntegrity)

    if self.Integrity ~= pastIntegrity then
        self.IntegrityChanged:Fire(pastIntegrity, self.Integrity)
    end

    -- Physically attach the organ part
    local weld = Instance.new("Weld") -- $ Might change this

    weld.Part0 = adornee
    weld.Part1 = organ.Model

    weld.c0 = offset or CFrame.identity

    weld.Parent = organ.Model

    if not self.Character:IsAncestorOf(organ.Model) then -- Don't reparent if its already in the character
        organ.Model.Parent = adornee
    end

    -- Connect to destroying
    organ.Destroying:Connect(self.RemoveOrgan)

    -- Fire attached signals
    self.OrganAttached:Fire(organ)
    organ.OnAttachment:Fire(self)
end

function Human:RemoveOrgan()
    
end

-- Destroy --
function Human:Destroy()

end

return function(char: Model, ...: Types.OrganTemplate): Types.Human -- Constructor
    assert(validateCharacter(char), "[Organs.Human]: Invalid character")

    local self = setmetatable({
        Character = char,
        Organs = setmetatable({}, organListMetatable),

        Integrity = 1,

        _maxIntegrity = 0, -- Hidden caches for faster calculation
        _currIntegrity = 0,

        IntegrityChanged = Signal.new<<number, number>>(),

        OrganRemoved = Signal.new<<Types.Organ>>(),
        OrganAttached = Signal.new<<Types.Organ>>(),

        Destroying = Signal.new()
    } :: Types.Human, Human)

    for _, template in {...} do
        local organ = Organ.fromTemplate(template)
        self:AttachOrgan(organ, getLimb(char, template.Adornee), template.Offset)
    end

    return self
end
