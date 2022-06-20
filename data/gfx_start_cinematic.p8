pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- picosonic gfx-only data:
-- start cinematic by leyn

-- This data is never used directly by the game, it is instead prebaked into the game by merging
--  it into the data_stage1_00 cartridge (which only needs its gfx at edit time to visualize tiles anyway,
--  so its original gfx can be overridden for build)
-- Note that this file must *not* be named with the "data_" prefix to avoid being copied like other cartridges
--  in the build pipeline scripts, so we prefer the "gfx_" prefix.
-- See install_data_cartridges_with_merging.sh

-- Import latest splash screen picture from carts/. Open data with pico8 -run for it to run automatically on launch.
import "spritesheet_titlemenu_start_cinematic.png"

-- this section will be overwritten during build
__gfx__
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeeee77778eeeeeeeeeeee8eeeeeeeeeeeeeeeeee8eeeeeeeeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeee7777788eeeeeeeeee272eeeeee2eeeeeeeee272eeeeee2ee
00700700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5775eeee2288822eeeeeeeee877782eee272e2eeee287778ee2e272e
00077000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee57775eeee28882eeeeeeeeeee272eeeeee2ee8eeeeee272eee8ee2ee
00077000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee577775eeee282eeeeeeeeeeeee8ee2eeeeee272eee2ee8eee272eeee
00700700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee57755eeeeee2eeeeeeeeeeeeee2e272eee287778e272e2ee877782ee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeeeeeeeeeeeeeeeeeeeeeeee2eeeeee272eee2eeeeee272eeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8eeeeeeeeeeee8eeeee
eeeeeeeeeeeeeeeeeedeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedeeeeeeeeeeeeeeeeeeeeededeedeeddeeeeeeeeeeeeeeeeeedeeeeee
eeeeeeeeeeeeee6eed6ddeeeeeeeeedeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeededeeddedddeedeeedeeeeeeeeeeee6ddd66dd76eeeeeeeeeeedee6d6d7d6eeee
eeeeeeeeeddeee6ddd66ddeedeed6ddddeedeeeeeeeeeeeeeeeeeeeeeeeeeee6ddd666d76dde6eee6eeeeeeeeeded7d67777677dedeeeeeeed6d66767777deee
eeeeeeeed66ddddd666666dddd66dd76dde6eeeeeeeeeeeeeeeeeeeeeeeeded7d6777767766d6dde7dedeeeeed6d676777777676d6deeeeed676777777776dee
eeeeeeeeed6777667777766d6777767766d6ddeeedeedeeeeeeeeeeeeeed6d6767777776776676dd76d6deeed677677777777776776deeeeed67777d6676deee
eeeeeeeedd677777677777767777776776676ddd66dd6deeeeeeeeeeeed67767777777777777777776776deeedd667777777777776eeeeeeeee6777dde6deeee
eeeeeed66677777777777777777777777777777777666deeeeeeeeee777777777777777777777777766ddeeeeedd667777d7766d66deeeeeeeed76deeedeeeee
eeeeee67777777777777777777777777777777777777777eeeeeeeeedd676677767777776777777776ddeeeeeeeed6666deed6deeeeeeeeeeeeeedeeeeeeeeee
eeee6d777777777777777777777777777777777777777777ddeeeeeeedd6d66767777766d67777676deeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeed7777777777777777777777777777777777777777777776deeeeeeee6edd6d666666dddd66dd7deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ed7777777777777777777777777777777777777777777777776deeeeeeedeeddddd66ddeedeededdeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
d7777777777777777777777777777777777777777777777777766ddeeeeeeeeeeed6ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ed77d777777777777777777777777777777777777777777776ddddeeeeeeeeeeeeedeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee6ed67777777777777777777777777777777777777777776ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeed67777777777777777777777777777777777777777ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee677777777776777777777776777777777777777777666deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeed66d6677d766676677777776777777776777667d7766ddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeed6deed6666666677766d66676776677766deed6deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeed6dddd66766ddd6d6d6666677deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeedddeed6dddede6dddd666d6deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeedddeeeededeed666edeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeededdeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111118a811111111111111111111111a811111111111111111111111111111111a8111111a8a1111111111118a11111111111111111111111111
1111111111111111111111111111111111111111111111111111111111aa811111111111111111111111111111111111111111111111111111118aa811111111
11111a8a11111111111111111111111111111111111111111111111111111111111111111111111111111111111ddddd11111111111111111111111111111111
11111111111111111111111118a1111111ddddddddd11111111111111111111111111111111111111111111ddddd6666dd11111111111188a111111111111111
11111111111111111111111111111111dddddd66dddd111111118a11111111111a81111111ddd111111111dd666666666dd111111a8111111111111111111111
1111111111ddd111dd11111111111dddddddddd6666dd1ddd111111111111111111111111dddd11111111dd66666767766ddd1111111111111111111111111dd
11111111dddddddddddd11111111dddddd676ddd6666ddddddd111111111111111111111dd67dd1111111d666666666666ddd1111111dddddddd11111111dddd
11dd1ddddd666ddddddddddddddddddddddddddddd666ddddddd1ddd11dd11111111111ddd1ddd11111dddd6dd666666d6ddddddddddd666666dd1111dddd666
1ddddddd666666dddddddddddd6d6776d6ddddddddddddddddddddddddddddddddddddddddddddd1111ddddddddd666dddddddddddddddd66666ddd1ddd66666
dddddddddddddddd6d676d6dddddddddddddddddddddddddddd76dddd67dd1ddddd67ddddddddd6676dddddddddddddddddd676d6ddddddddd666ddddddd66dd
dddddddddddddddddddddddddddddddddddddddddddddddddddddd67dddddddd1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
77777777777777777777777777777777dd777ddddddd7777dddddddddddddddddddddddddddddddddddddddddddd77777ddddddddddddddd7777777766777777
667777777777777777777777777777777777777777777777777667776777777777777777777777777777ddddddd7777777777777777777777777777767777777
d6777777777777777777777777777777777777777777777677777776677777777777777777777777777777777777777777777777777777777777777667777777
ed677777777777777777777777777777777777777777776777777777767777766666776777777766777777777777776777777777777777776777776676777777
eed66677777777777777777777777677777777777777777777777777666666d6666e666677777767777777777777677777776667777777767777777777777777
eee66777777777777777777777777677777777777777777777777776666666dd66deeeee677776677777777777767766667e6666666667777766776766777777
eee66777777777777777777766677777777777777777777777777776d666deeeeeeeeeeee66666e67777777767677776666eeeee666666776666666dee677777
eeee6677777777777777777766677777777777777777777777777766eeeeeeeeeeeeeeeeee66eee66777777677777777666eeeeeeeeed666666ddeeeeee66776
eeeed66777777777776777766677777777767777777777777777776deeeeeeeeeeeeeeeeeeeeeeeee666666777777777766eeeeeeeeeedddddddeeeeeeeeddd6
eeeeee666777777777d666666677777777777677777777777777766eeeeeeeeeeeeeeeeeeeeeeeeeee666e6777777777666eeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeed7777777776deeed666677777777776777777777777777deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee67777777766eeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee777776776deeeeeddedd6677777777777777777777777deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee6677677776eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeed67776ddddeeeeeeeeeeed677777777777777777777777deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddd67776deeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeedd66eeeeeeeeeeeeeeeeed67777777777777777777776deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed66deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeed6777777777777777777776deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeed677777777777777777666deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeed77777777777777777deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeed67777777777777776deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedd666777777777776deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed67777776666deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed67777776ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed677776deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed6766deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ecceeeeec7ceeeeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
cceeeeeecc7eeeeeeee8eeeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
fcceeeeeccceeeeeee272eeeee878eeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
c7eeeeeeeeeeeeee2877782ee27772eeee272eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
78eeeeeeeeeeeeeeee272eeeee878eeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee8eeeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeee8eeeeeeeeeeeeeee8eeeeeeeeeeeeeee8eeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee7766e49eee97eeee7766e49eee97eeee7766e49eee97eeee7766e49eee97eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeedede74ee222eeeeedede74ee222eeeeedede74ee222eeeeedede74ee222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee6d5052888898eeeeed5052888898eeee5d5052888898eeeeed5052888898eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee8726682622eeeeee5726682622eeeeee8726682622eeeeee5726682622eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee5d000eeeeeeeeeeeed000eeeeeeeeeee6d000eeeeeeeeeeeed000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0566679eeeeeeeee05666779eeeeeeee0566679eeeeeeeee05666779eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed6766deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed677776deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed67777776ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed67777776666deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeedd666677777777776deeeeeeeeeeeeeeeeeeeeeeeeeeeeee97eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeed67777777777777776deeeeeeeeeeeeeeeeeeeeeeeeeeeee249eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeed77777777777777777deeeeeeeeeeeeeeeeeeeeeeeeeeeee249eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeed677777777777777777666deeeeeeeeeeeeeeeeeeeeeeeeee249eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeed6777777777777777777776deeeeeeeeeeeeeeeeeeeeeeee2249eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeedd66eeeeeeeeeeeeeeeeed67777777777777777777776deeeeeeeeeeeeeeeeeeeeeee2249eeeeeeeeeeed66deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeed67776ddddeeeeeeeeeeed667772477777777777777777deeeeeeeeeeeeeeeeeeeeeee22449eeeeeeddd67776de24eeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee777776776deeeeeddedd6667772477777777777777777deeeeeeeeeeeeeeeeeeeeeee22449eeeee6677677776e24eeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeed7777777776deeed666677777772277777777777777777deeeeeeeeeeeeeeeeeeeeee2224249749e6777777776622eeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee666777777777d666666677777777227777777777777777766eeeeeeeeeeeeeeeeeeee2122422444967777777776622eeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeed66777777777776777766677777777224977777777777777776deeeeeeeeeeeee99eeee221222244246777777777762249eeeeeeedddddddeeeeeeeeddd6
eeee6677777777777777777766677777772249777777777777777766eeeeeeeeeeeee49eee2212222244249649777777662249eeeeeed666666ddeeeeee66776
eee66777777777777777777766677777272229729777777777777776d666deeeeeeee294942121221224244929677776262229e2966666776666666dee677777
eee66777777777777777777777777677242224229777777777777776666666dd66de424494b3bb121b2224442496776924222422966667777766776766777777
eed66677777777777777777777777677222222229477777777777777666666d6666442bbb1333bb1b3b2b2442249696422222222947777767777777777777777
ed677777777777777777777777777774222b2222224774677777777776777776643422b3b331333bb3bbbbb222444964222b2222224977776777776676777777
d677777777777777777777777777244421313b22322424467777777667777744bb3b3333b33313333bb3333b1324444223113b22322429777777777667777777
66777777777777777777777777772333131313bb333332244966677767777744333333341221313331333b1113b32224111313b1333332244977777767777777
7777777777777777777777777442233331111113311131322224ddddddddd43b31122424242211311111331b3333113331111113311131322224777766777777
ddddddddddddddddddddddddddddddd11dd11dd13bdddd11dddddd67dddddddd1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddd6d676d6dddddddddddddddddddddddddddd76dddd67dd1ddddd67ddddddddd6676dddddddddddddddddd676d6ddddddddd666ddddddd66dd
1ddddddd666666dddddddddddd6d6776d6ddddddddddddddddddddddddddddddddddddddd1dddddddddddddddddd666dddddddddddddddd66666ddd1ddd66666
11dd1ddddd666ddddddddddddddddddddddddddddd666ddddddd1ddd11dd111111111dd1111ddddddd1dddd6dd666666d6ddddddddddd666666dd1111dddd666
11111111dddddddddddd11111111dddddd676ddd6666ddddddd1111111111111111111111111dd67dd111d666666666666ddd1111111dddddddd11111111dddd
1111111111ddd111dd11111111111dddddddddd6666dd1ddd1111111111111111111111111111dddd1111dd66666767766ddd1111111111111111111111111dd
11111111111111111111111111111111dddddd66dddd111111118a11111111111a81111111111dddd11111dd666666666dd111111a8111111111111111111111
11111111111111111111111118a1111111ddddddddd11111111111111111111111111111a81111dd1111111ddddd6666dd11111111111188a111111111111111
11111a8a11111111111111111111111111111111111111111111111111111111111111111111111111111111111ddddd11111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111aa811111111111111111111111111111111111111111111111111111118aa811111111
111111111111111118a811111111111111111111111a811111111111111111111111111111111a8111111a8a1111111111118a11111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
