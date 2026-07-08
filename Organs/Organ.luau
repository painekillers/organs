local Types = require("@self/Types")

local Organ = {} :: Types.Organ
Organ.__index = Organ

-- Cutting Functions --
function Organ:SphereCute()
    
end

function Organ:BoxCut()
    
end

function Organ:Pierce()
    
end

function Organ:Slice()
    
end

-- Repair Functions --
function Organ:PartialRepair()
    
end

function Organ:Repair()
    
end

-- Destroy --
function Organ:Destroy()
    
end

-- Constructors --
local function new()
    
end

local function fromTemplate()
    
end

return {fromTemplate = fromTemplate, new = new}