local Signal = require("@self/Signal")

local Types = require("@self/Types")
type Signal<T...> = Signal.Signal<T...>

local Organ = require("@self/Organ")

local Human = {} :: Types.Human
Humand.__index = Human

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

-- Reset Function --
function Human:Reset()
    for _, organ in self.Organs do
        organ:Repair()
    end
end

-- Attaching and Removing Organs --
function Human:AttachOrgan()
    
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
        Organs = {},

        IsBleeding = false,
        Integrity = 1,

        IntegrityChanged = Signal.new<<number, number>>(),
        BleedingChanged = Signal.new<<boolean>>(),

        OrganRemoved = Signal.new<<Types.Organ>>(),
        OrganAttached = Signal.new<<Types.Organ>>(),

        Destroying = Signal.new()
    } :: Types.Human, Human)

    for _, template in {...} do
        local organ = Organ.fromTemplate(template)
        self:AttachOrgan(organ, template.Adornee, template.Offset)
    end

    return self
end
