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
    read Name: string,

    read Model: BasePart | Limb, -- Can be a part already in the character based on name

    read Adornee: Limb,
    read Offset: CFrame?,

    read AttachmentSetting: AttachmentSetting,
}

export type Snapshot = {
    read Model: BasePart?,
    read Integrity: number?,
}

export type AttachmentSetting = "Overlap" | "Weld"
--[[
    Overlap: Parts of the organ that overlaps with its adornee remains attached
    Weld: Parts of the organ that is connected to the weld (weld point is within part) remains attached
]]

export type CutSetting = "None" | "Single" | "Overlap"

export type QuerySettings = {
    Radius: number?,
    Power: number?,
    Falloff: ((dist: number) -> number)?,

    CutSetting: CutSetting
}

export type QueryResult = {
    read Hit: Organ?,

    read Contact: Vector3?, -- First point that gets hit
    read End: Vector3?, -- Point which the query ends (Ran out of power or start + direction)

    read Normal: Vector3?, -- Normal of the surface that was hit

    read Power: number?, -- Remaining Power

    read Organs: {Organ}? --Everything that was cut if CutSetting is set to Overlap
}

export type OrganModule = {
    read Setup: (char: Model, ...OrganTemplate) -> Human, -- Sets up character as human
    read Organ: (model: BasePart, integrityWeight: number?, attach: AttachmentSetting?) -> Organ, -- Creates organ

    read SphereCut: (center: Vector3, radius: number, included: {Human}) -> {Organ},
    read BoxCut: (cf: CFrame, size: Vector3, included: {Human}) -> {Organ},
    
    read Pierce: (start: Vector3, direction: Vector3, included: {Human | Organ}, excluded: {Organ}?, settings: QuerySettings?) -> QueryResult,
    read Slice: (start: Vector3, path: (t: number) -> CFrame, included: {Human | Organ}, excluded: {Organ}?, settings: QuerySettings?, stepSize: number?) -> QueryResult, -- Path takes alpha and returns (position, upvector)

    --  Didn't want to do this but it makes more sense
    read PartToOrgan: (instance: BasePart) -> Organ?,
    read ModelToHuman: (model: Model) -> Human?,
}

export type Human = {
    Character: Model,
    Organs: {[string]: Organ | {Organ}}, -- If identical name then is array

    Integrity: number, -- Sum(Organ Integrity) / #Organs

    read Reset: (self: Human) -> (), -- Resets all organs to their initial state

    read AttachOrgan: (self: Human, organ: Organ, adornee: BasePart, offset: CFrame?) -> (), -- Attaches an organ to the human
    read RemoveOrgan: (self: Human, organ: Organ | number) -> (), -- Removes an organ

    read Destroy: (self: Human) -> (), -- Disconnects Human object from the character and cleans up

    read IntegrityChanged: Signal<number, number>,

    read OrganRemoved: Signal<Organ>, -- Fires when an organ is removed from the human
    read OrganAttached: Signal<Organ>, -- Fires when an organ is attached to the human

    Destroying: Signal<>
}

export type Organ = {
    Name: string,

    Model: BasePart,
    Adornee: BasePart?,
    Weld: Weld?, -- $ Might not actually use weld instances here

    Owner: Human?,

    AttachmentSetting: AttachmentSetting,

    read IntegrityWeight: number?, --How much it contributes to the Human

    Integrity: number, -- How much of the organ is still connected (0 = completely severed, 1 = fully connected)

    Snapshots: {Snapshot}, -- Save only the changes brah

    --These functions are solely for cutting the organ model, they are not spatial queries
    read SphereCut: (self: Organ, center: Vector3, radius: number) -> (),
    read BoxCut: (self: Organ, cf: CFrame, size: Vector3) -> (),
    read Pierce: (self: Organ, start: Vector3, direction: Vector3, settings: QuerySettings?) -> (),
    read Slice: (self: Organ, start: Vector3, path: (t: number) -> CFrame, settings: QuerySettings?, stepSize: number?) -> (), -- Path takes alpha and returns (position, upvector)

    read PartialRepair: (self: Organ, progress: number?) -> (), --ignoreDamageOnly ignores snapshots that do not change integrity if set to true
    read Repair: (self: Organ, progress: number?) -> (), 
    --[[
        Repairing restores integrity and physical model based on its previous snapshot
        The Repair function uses the initial snapshot while PartialRepair uses the most recent snapshot
        Progress is a number between 0 and 1 which represents a state somewhere between the current state and the snapshot state.
        When progress is nil, it is treated as 1 (A reversion)
    ]]

    read Destroy: (self: Organ) -> (), -- Fully destroys the Organ object

    read IntegrityChanged: Signal<number, number>,

    read OnRemoval: Signal<Human>, -- When removed from human
    read OnAttachment: Signal<Human>, -- When attached to human

    read Destroying: Signal<Human?, Organ> -- Pass its owner and itself so we don't need to make an anonymous function to remove it on destruction
}

return nil