export type VapeSlider = {
    Value: any,
    Object: Frame
}
export type VapeDropdown = VapeSlider

export type VapeToggle = {
    Enabled: boolean,
    Toggle: (self: VapeToggle, ...any) -> (),
    Object: Frame,
    Clean: (self: VapeToggle, any) -> RBXScriptConnection
}

export type VapeModule = VapeToggle & {
    CreateSlider: (...any) -> VapeSlider, 
    CreateToggle: (...any) -> VapeToggle,
    CreateDropdown: (...any) -> VapeDropdown,
    CreateButton: (...any) -> ()
}

export type VapeCategory = {
    CreateModule: (self: VapeCategory, any) -> VapeModule
}