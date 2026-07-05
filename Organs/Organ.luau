local Types = require("@self/Types")

local Organ = {} :: Types.Organ
Organ.__index = Organ

-- Damage --
function Organ:Damage(damage: number)
    self.Health = math.clamp(self.Health - damage, 0, self.MaxHealth)

    self.HealthChanged:Fire(self.Health)
end

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