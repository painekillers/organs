local Signal = require("./Signal")

type Signal<T...> = Signal.Signal<T...>

export type Limb = string

export type OrganTemplate = {
    Model: BasePart | Limb, -- Can be a part already in the character based on name

    Adornee: Limb, -- $ How do I type this as limb names brah
    Offset: CFrame?,

    BloodSetting: BloodSetting,
    IntegrityDamageSetting: IntegrityDamageSetting,
    CanBleed: boolean,

    MaxHealth: number,
}

export type Snapshot = {
    Model: BasePart?,
    Integrity: number?,

    IsBleeding: boolean?,
    Health: number?,
}

export type BloodSetting = "NoBlood" | "Cosmetic" | "Health"
export type IntegrityDamageSetting = "None" | "Remaining" | "Full"
--[[
    Remaining: Damage is applied as Health - (1 - (newIntegrity / oldIntegrity)) * Health
    Full: Damage is applied as Health - (oldIntegrity - newIntegrity) * MaxHealth
]]

export type QueryResult = {
    Hit: Organ?,

    Contact: Vector3?, -- First point that gets hit
    End: Vector3?, -- Point which the query ends (Ran out of power or start + direction)

    Normal: Vector3?, -- Normal of the surface that was hit

    Power: number?,
}

export type OrganModule = {
    Setup: (char: Model, blood: BloodSetting, ...(OrganTemplate | Organ)?) -> Human, -- Sets up character as human
    Organ: (model: BasePart, MaxHealth: number, canBleed: boolean?, blood: BloodSetting?, integrity: IntegrityDamageSetting?) -> Organ, -- Creates organ

    SphereCut: (center: Vector3, radius: number, included: {Human}, damage: number | (remaining: number) -> number | nil) -> {Organ},
    BoxCut: (cf: CFrame, size: Vector3, included: {Human}, damage: number | (remaining: number) -> number | nil) -> {Organ},
    
    Pierce: (start: Vector3, direction: Vector3, included: {Human | Organ}, excluded: {Organ}?, radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> QueryResult,
    Slice: (start: Vector3, path: (t: number) -> (Vector3, Vector3), included: {Human | Organ}, excluded: {Organ}?, radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> QueryResult, -- Path takes alpha and returns (position, upvector)

    --  Didn't want to do this but it makes more sense
    PartToOrgan: (instance: BasePart) -> Organ?,
    ModelToHuman: (model: Model) -> Human?,
}

export type Human = {
    Character: Model,
    Organs: {Organ},

    BloodSetting: BloodSetting,

    IsBleeding: boolean, -- Is any organs bleeding?

    --[[
        Health is not included as a Human is only a sum of its organs
        This allows users to use the Human object with their own implementation of health and other things
    ]]

    Integrity: number, -- Sum(Organ Integrity) / #Organs

    Reset: (self: Human) -> (), -- Resets all organs to their initial state

    AttachOrgan: (self: Human, organ: Organ, adornee: BasePart, offset: CFrame?) -> (), -- Attaches an organ to the human
    RemoveOrgan: (self: Human, organ: Organ) -> (), -- Removes an organ

    Destroy: (self: Human) -> (), -- Disconnects Human object from the character and cleans up

    IntegrityChanged: Signal<number>,
    BleedingChanged: Signal<boolean>,

    OrganHealthChanged: Signal<Organ, number>, -- Fires when an organ's health changes

    OrganRemoved: Signal<Organ>, -- Fires when an organ is removed from the human
    OrganAttached: Signal<Organ>, -- Fires when an organ is attached to the human

    Destroying: Signal<>
}

export type Organ = {
    Model: BasePart,
    Adornee: BasePart?,
    Weld: Weld?, -- $ Might not actually use weld instances here

    Owner: Human?,

    BloodSetting: BloodSetting,
    IntegrityDamageSetting: IntegrityDamageSetting,
    CanBleed: boolean,

    IsBleeding: boolean,

    MaxHealth: number,
    Health: number,
    Integrity: number, -- How much of the organ is still connected (0 = completely severed, 1 = fully connected)

    Snapshots: {Snapshot}, -- Save only the changes brah

    Damage: (self: Organ, damage: number) -> (),

    --These functions are solely for cutting the organ model, they are not spatial queries
    SphereCut: (self: Organ, center: Vector3, radius: number, damage: number | (remaining: number) -> number | nil) -> (),
    BoxCut: (self: Organ, cf: CFrame, size: Vector3, damage: number | (remaining: number) -> number | nil) -> (),
    Pierce: (self: Organ, start: Vector3, direction: Vector3, radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> (),
    Slice: (self: Organ, start: Vector3, path: (t: number) -> (Vector3, Vector3), radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> (), -- Path takes alpha and returns (position, upvector)

    Heal: (self: Organ, amount: number) -> (), -- Only affects Health
    PartialRepair: (self: Organ, ignoreDamageOnly: boolean, progress: number?) -> (), --ignoreDamageOnly ignores snapshots that do not change integrity if set to true
    Repair: (self: Organ, progress: number?) -> (), 
    --[[
        Repairing restores integrity and physical model based on its previous snapshot
        The Repair function uses the initial snapshot while PartialRepair uses the most recent snapshot
        Progress is a number between 0 and 1 which represents a state somewhere between the current state and the snapshot state.
        When progress is nil, it is treated as 1 (A reversion)
    ]]

    Destroy: (self: Organ) -> (), -- Fully destroys the Organ object

    IntegrityChanged: Signal<number>,
    HealthChanged: Signal<number>, 
    BleedingChanged: Signal<boolean>, 

    OnRemoval: Signal<Human>, --When removed from human
    OnAttachment: Signal<Human>, --When attached to human

    Destroying: Signal<>
}

return nil