local Signal = require("./Signal")

type Signal<T...> = Signal.Signal<T...>

export type Limb = 
    | "HumanoidRootPart" 
    | "Head" 
    | "Torso" 
    | "Left Arm" 
    | "Right Arm" 
    | "Left Leg" 
    | "Right Leg" 
    | "UpperTorso"
    | "LowerTorso"
    | "LeftUpperArm"
    | "LeftLowerArm"
    | "LeftHand"
    | "RightUpperArm"
    | "RightLowerArm"
    | "RightHand"
    | "LeftUpperLeg"
    | "LeftLowerLeg"
    | "LeftFoot"
    | "RightUpperLeg"
    | "RightLowerLeg"
    | "RightFoot"
    | string

export type OrganTemplate = {
    read Model: BasePart | Limb, -- Can be a part already in the character based on name

    read Adornee: Limb, -- $ How do I type this as limb names brah
    read Offset: CFrame?,

    read BloodSetting: BloodSetting,
    read IntegrityDamageSetting: IntegrityDamageSetting,
    read CanBleed: boolean,

    read MaxHealth: number,
}

export type Snapshot = {
    read Model: BasePart?,
    read Integrity: number?,

    read IsBleeding: boolean?,
    read Health: number?,
}

export type BloodSetting = "NoBlood" | "Cosmetic" | "Health"
export type IntegrityDamageSetting = "None" | "Remaining" | "Full"
--[[
    Remaining: Damage is applied as Health - (1 - (newIntegrity / oldIntegrity)) * Health
    Full: Damage is applied as Health - (oldIntegrity - newIntegrity) * MaxHealth
]]

export type QueryResult = {
    read Hit: Organ?,

    read Contact: Vector3?, -- First point that gets hit
    read End: Vector3?, -- Point which the query ends (Ran out of power or start + direction)

    read Normal: Vector3?, -- Normal of the surface that was hit

    read Power: number?,
}

export type OrganModule = {
    read Setup: (char: Model, blood: BloodSetting, ...(OrganTemplate | Organ)?) -> Human, -- Sets up character as human
    read Organ: (model: BasePart, MaxHealth: number, canBleed: boolean?, blood: BloodSetting?, integrity: IntegrityDamageSetting?) -> Organ, -- Creates organ

    read SphereCut: (center: Vector3, radius: number, included: {Human}, damage: number | (remaining: number) -> number | nil) -> {Organ},
    read BoxCut: (cf: CFrame, size: Vector3, included: {Human}, damage: number | (remaining: number) -> number | nil) -> {Organ},
    
    read Pierce: (start: Vector3, direction: Vector3, included: {Human | Organ}, excluded: {Organ}?, radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> QueryResult,
    read Slice: (start: Vector3, path: (t: number) -> (Vector3, Vector3), included: {Human | Organ}, excluded: {Organ}?, radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> QueryResult, -- Path takes alpha and returns (position, upvector)

    --  Didn't want to do this but it makes more sense
    read PartToOrgan: (instance: BasePart) -> Organ?,
    read ModelToHuman: (model: Model) -> Human?,
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

    read Reset: (self: Human) -> (), -- Resets all organs to their initial state

    read AttachOrgan: (self: Human, organ: Organ, adornee: BasePart, offset: CFrame?) -> (), -- Attaches an organ to the human
    read RemoveOrgan: (self: Human, organ: Organ) -> (), -- Removes an organ

    read Destroy: (self: Human) -> (), -- Disconnects Human object from the character and cleans up

    read IntegrityChanged: Signal<number>,
    read BleedingChanged: Signal<boolean>,

    read OrganHealthChanged: Signal<Organ, number>, -- Fires when an organ's health changes

    read OrganRemoved: Signal<Organ>, -- Fires when an organ is removed from the human
    read OrganAttached: Signal<Organ>, -- Fires when an organ is attached to the human

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

    read MaxHealth: number,

    Health: number,
    Integrity: number, -- How much of the organ is still connected (0 = completely severed, 1 = fully connected)

    Snapshots: {Snapshot}, -- Save only the changes brah

    read Damage: (self: Organ, damage: number) -> (),

    --These functions are solely for cutting the organ model, they are not spatial queries
    read SphereCut: (self: Organ, center: Vector3, radius: number, damage: number | (remaining: number) -> number | nil) -> (),
    read BoxCut: (self: Organ, cf: CFrame, size: Vector3, damage: number | (remaining: number) -> number | nil) -> (),
    read Pierce: (self: Organ, start: Vector3, direction: Vector3, radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> (),
    read Slice: (self: Organ, start: Vector3, path: (t: number) -> (Vector3, Vector3), radius: number?, power: number?, falloff: ((dist: number) -> number)?) -> (), -- Path takes alpha and returns (position, upvector)

    read Heal: (self: Organ, amount: number) -> (), -- Only affects Health
    read PartialRepair: (self: Organ, ignoreDamageOnly: boolean, progress: number?) -> (), --ignoreDamageOnly ignores snapshots that do not change integrity if set to true
    read Repair: (self: Organ, progress: number?) -> (), 
    --[[
        Repairing restores integrity and physical model based on its previous snapshot
        The Repair function uses the initial snapshot while PartialRepair uses the most recent snapshot
        Progress is a number between 0 and 1 which represents a state somewhere between the current state and the snapshot state.
        When progress is nil, it is treated as 1 (A reversion)
    ]]

    read Destroy: (self: Organ) -> (), -- Fully destroys the Organ object

    read IntegrityChanged: Signal<number>,
    read HealthChanged: Signal<number>, 
    read BleedingChanged: Signal<boolean>, 

    read OnRemoval: Signal<Human>, --When removed from human
    read OnAttachment: Signal<Human>, --When attached to human

    read Destroying: Signal<>
}

return nil