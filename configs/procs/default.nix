{ ... }:
{ ... }:
{
  xdg.configFile."procs/config.toml".text = ''
    [[columns]]
    kind = "Pid"
    style = "BrightYellow|Yellow"
    numeric_search = true
    nonnumeric_search = false

    [[columns]]
    kind = "User"
    style = "BrightGreen|Green"
    numeric_search = false
    nonnumeric_search = true

    [[columns]]
    kind = "Separator"
    style = "White|BrightBlack"

    [[columns]]
    kind = "Tty"
    style = "BrightWhite|Black"

    [[columns]]
    kind = "UsageCpu"
    style = "ByPercentage"
    align = "Right"

    [[columns]]
    kind = "UsageMem"
    style = "ByPercentage"
    align = "Right"

    [[columns]]
    kind = "CpuTime"
    style = "BrightCyan|Cyan"

    [[columns]]
    kind = "MultiSlot"
    style = "ByUnit"
    align = "Right"

    [[columns]]
    kind = "Separator"
    style = "White|BrightBlack"

    [[columns]]
    kind = "Command"
    style = "BrightWhite|Black"
    nonnumeric_search = true

    [display]
    cut_to_terminal = false
    cut_to_pager = false
    cut_to_pipe = false
  '';
}
