local Signal = require("@self/Signal")

local Types = require("@self/Types")
type Signal<T...> = Signal.Signal<T...>

local Organ = require("@self/Organ")
local Human = require("@self/Human")

local OrganModule = {} :: Types.OrganModule

local organSave: {[number]: Types.Organ} = {}
local organID: number = 0

local humSave: {[number]: Types.Human} = {}
local humID: number = 0

-- Constructors --
function OrganModule.SetUp(char: Model, ...: Types.OrganTemplate): Types.Human
    local hum = Human(char, ...)

    local id = humID
    humID += 1

    humSave[id] = hum
    
    hum.Destroying:Connect(function()
        humSave[id] = nil
    end)
    
    return hum
end

function OrganModule.Organ()

end

-- Queries --
function OrganModule.SphereCut()

end

function OrganModule.BoxCut()

end

function OrganModule.Pierce()

end

function OrganModule.Slice()

end

-- Lookup --
function OrganModule.PartToOrgan(instance: BasePart): Types.Organ?
    return organSave[instance:GetAttribute("OrganID")]
end

function OrganModule.ModelToHuman(model: Model): Types.Human?
    return humSave[model:GetAttribute("HumanID")]
end

return OrganModule