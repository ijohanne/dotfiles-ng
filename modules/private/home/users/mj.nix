{ user, modules, ... }:

{
  imports = [
    (import modules.public.homeManager.aspects.cliBase { })
    (import modules.public.homeManager.programs.bash { })
    (import modules.public.homeManager.programs.zsh { })
  ];

  programs.${user.shell}.enable = true;
}
