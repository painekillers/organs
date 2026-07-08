local Signal = require("@self/Signal")

local Types = require("@self/Types")
type Signal<T...> = Signal.Signal<T...>

local Organ = require("@self/Organ")

local Human = {} :: Types.Human
Humand.__index = Human

-- Helpers --
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
        warn(`[Organs.Human] Failed to attach organ {organ.Name} to {self.Character and self.Character.Name or "Unknown"} because adornee is invalid`)
        return
    end

    -- Adding the Organ in the object
    assert(not self.Organs[organ.Name], `[Organs.Human] {self.Character and self.Character.Name or "Unknown"} already has an organ named {organ.Name}`)
    organ.Owner = self

    self.Organs[organ.Name] = organ

    -- Handling integrity change
    local pastIntegrity = self.Integrity

    self._maxIntegrity += organ.IntegrityWeight or 0
    self._currIntegrity += organ.Integrity * organ.IntegrityWeight

    self.Integrity = calculateIntegrity(self._maxIntegrity, self._currIntegrity)

    if self.Integrity ~= pastIntegrity then
        self.IntegrityChanged:Fire(pastIntegrity, self.Integrity)
    end

    -- Update integrity when organ integrity changes
    local integrityConn = organ.IntegrityChanged:Connect(function(old: number, new: number) -- This doesn't seem optimal but idrk how to change it
        local pastIntegrity = self.Integrity

        local delta = old - new

        self._currIntegrity += delta

        self.Integrity = calculateIntegrity(self._maxIntegrity, self._currIntegrity)

        if self.Integrity ~= pastIntegrity then
            self.IntegrityChanged:Fire(pastIntegrity, self.Integrity)
        end
    end)

    table.insert(self._conn[organ.Name], integrityConn)

    -- Physically attach the organ part
    local weld = Instance.new("Weld") -- $ Might change this
    weld.Name = organ.Name.."_Weld"
    -- $ Potentially run :GetJoints to use existing constraints if they exist

    weld.Part0 = adornee
    weld.Part1 = organ.Model

    weld.c0 = offset or CFrame.identity

    weld.Parent = organ.Model

    if not self.Character:IsAncestorOf(organ.Model) then -- Don't reparent if its already in the character
        organ.Model.Parent = adornee
    end

    -- Connect to destroying
    table.insert(self._conn[organ.Name], organ.Destroying:Connect(self.RemoveOrgan))

    -- Fire attached signals
    self.OrganAttached:Fire(organ)
    organ.OnAttachment:Fire(self)
end

function Human:RemoveOrgan(organ: Types.Organ | string)
    local index

    if typeof(organ) == "string" then
        index = organ
        organ = self.Organs[index] :: Types.Organ

        assert(organ, `[Organs.Human] Could not find organ of name {index} in {self.Character and self.Character.Name or "Unknown"}`)
    else
        index = organ.Name
        organ = organ :: Types.Organ -- Funny but I do need this

        if not self.Organs[index] or organ.Owner ~= self then
            warn(`[Organs.Human] The owner value of {index} or the organs table of {self.Character and self.Character.Name or "Unknown"} does not contain the other`)
        end
    end

    -- Remove organ from object
    self.Organs[index] = nil
    organ.Owner = nil

    -- Handling integrity change
    local pastIntegrity = self.Integrity

    self._maxIntegrity -= organ.IntegrityWeight or 0
    self._currIntegrity -= organ.Integrity * organ.IntegrityWeight

    self.Integrity = calculateIntegrity(self._maxIntegrity, self._currIntegrity)

    if self.Integrity ~= pastIntegrity then
        self.IntegrityChanged:Fire(pastIntegrity, self.Integrity)
    end

    -- Physically detach the part
    local weld: Weld = script:FindFirstChild(organ.Name.."_Weld") -- $ Potentially fallback to GetJoints or use GetJoints initially

    if not weld or (weld.Part0 ~= organ.Model and weld.Part1 ~= organ.Model) then
        warn(`[Organs.Human] Could not find weld for {index} in {self.Character and self.Character.Name or "Unknown"}`)
    else
        weld:Destroy()

        -- We don't re-parent the organ directly and allow user to decide behaviour
        -- This is fine because this function is only called upon organ.Destroying, human:Destroy() and user wishing to remove the organ manually
    end

    -- Disconnect connections
    local connections = self.__conn[organ.Name]

    if connections then
        for _, conn in connections :: {Signal.Connection} do
            conn:Disconnect()
        end
    end

    -- Fire removed signals
    self.OrganRemoved:Fire(organ)
    organ.OnRemoval:Fire(self)
end

-- Destroy --
function Human:Destroy(): {Types.Organ} -- All the removed organs (So you can do with them what you want)
    -- Fire destroying signal
    self.Destroying:Fire()

    -- Remove Organs ( $ Potentially do this after we DisconnectAll on the signals if we don't wish for Removed to fire)
    local removed = {}
    
    for name, organ in self.Organs do
        self:RemoveOrgan(name) -- $ Not sure if using name or organ is better actually
        removed[name] = organ -- Shallow copy lol
    end

    -- Remove character reference
    self.Character = nil

    -- Disconnect signals
    self.IntegrityChanged:DisconnectAll()
    self.OrganRemoved:DisconnectAll()
    self.OrganAttached:DisconnectAll()

    self.Destroying:DisconnectAll()

    return removed
end

return function(char: Model, ...: Types.OrganTemplate): Types.Human -- Constructor
    assert(validateCharacter(char), "[Organs.Human] Invalid character")

    local self = setmetatable({
        Character = char,
        Organs = {},

        Integrity = 1,

        _maxIntegrity = 0, -- Hidden caches for faster calculation
        _currIntegrity = 0,

        IntegrityChanged = Signal.new<<number, number>>(),

        OrganRemoved = Signal.new<<Types.Organ>>(),
        OrganAttached = Signal.new<<Types.Organ>>(),

        _conn = {} :: {[string]: {Signal.Connection}}, -- Internal connection table to disconnect

        Destroying = Signal.new()
    } :: Types.Human, Human)

    for _, template in {...} do
        local organ = Organ.fromTemplate(template)
        self:AttachOrgan(organ, getLimb(char, template.Adornee), template.Offset)
    end

    return self
end
