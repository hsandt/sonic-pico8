pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- picosonic data:
-- runtime spritesheet by leyn

-- Import latest spritesheet. Open data with pico8 -run for it to run automatically on launch.
import "spritesheet_stage_intro.png"

__gfx__
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00700700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00077000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee57775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00077000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee577775eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00700700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee57755eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
eeeeeeeebbbbbbbbbbbbbbbbbbbb3bbbb3bbbbbbbbbbbb3bbbbbbb3bbababbabbabbababb3bbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeebb0bb3b3bb3bb0bbbbb303bbb3b3bb3bb3bb3b3bb3b3bbbbb3bbbbabbabbbbbbbbbb3b3beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee3003b030b30b30033b300033bbbbbb3bb3bbbbbbbbb3bb3bb3bbbbbbbbbb3b3bb3bb3bbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee004030003003040003004000bbbb0bbbbbb0bbbb3bbbb33bbbbb3b3bbbbbbb3bb33bbbb3eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee044400440000044440044440b03b03bbbb30b30b033b303bbbbbbb3bbb3bbbbbb303b330eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee444444444400449444444444000b00b03b00b00003033003bbbbbbbbbb3bbbbb30033030eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee444944444404449444494444040300300300304040003040b3b3bbbbbbbb3b3b30400000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee4444444444444444444944444440040000440444404004403bb3bb3bb3bb3bb304400404eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee4444444494444444bb3bbbb33bbbbbbb0b30b30bb3bb03b03bbbb3bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444449999494444
eeeeeeeeeeeeeeeeeeeeeeee4449444494944444bbbb3b300bb3b3b30030b00bb03b030003b3bbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444949999444444
eeeeeeeeeeeeeeeeeeeeeeee4444494444444444b3bb3b0403b333b040003003b003000440b3bb3beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4344999994494444
eeeeeeeeeeeeeeeeeeeeeeee4444494994444444b33bbb0440303030440400403000404440bbb33beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4b34394999494444
eeeeeeeeeeeeeeeeeeeeeeee44444449949444443003b304400000004444444004044444403b3003eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3bb4b94999994444
eeeeeeeeeeeeeeeeeeeeeeee44449499994444440403300444040404444494440444444440033040eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbb3999999944b3
eeeeeeeeeeeeeeeeeeeeeeee44449499494944444440304444444444444494444449444444030444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb33bb939993b43bb
eeeeeeeeeeeeeeeeeeeeeeee44449449494944444444004444444444444444444444444444004444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebb33b3b3393b3bbb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebb3b3bbbbb3bbb3b
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb3bb33bbb333bb3b
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee03b3bbbbb3b3b3b0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb03bbb333bbbbbb0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb333bbbbb33b30bb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb3bbb3bb30033bbb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3bb330bbbb3b33bb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbbb0bbb33bb3bb
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee33eeeb33eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444444499949444494494444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeee33e333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee444449499444444494444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeee3033eee33eeeb33eeeeeeeeeeeeeeeeeeeeeeeeeee444449499444444499494444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee33eeeb33e3333330333e33e333eeeeeeeeeeeeeeeeeeeeeeeeeeee444444499949444499444944eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee33e333eeee3033033eee3033eeeeeeeeeeeeeeeeeeeeeeeeeeeee444444499944444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee3033eeee333333eee33333033e3eeeeeeeeeeeeeeeeeeeeeeeee444494949994444444004444deeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e333333333eeee333333ee303333ee33eeeeeeeeeeeeeeeeeeeeeeee444494949949444440000044edeeeeeeeeeeeeeeeeee44eeeeeeeeeeeeeeeeeeeeeeeeee
3ee303e03ee33333303bb3333333e333eeeeeeeeeeeeeeeeeeeeeeee444494999949444400000004deeeeeeeeeeeeeeeeee944eeeeeeeeeeeeeeeeeeeeeeeeee
03bb03333333303333b3333b33333333eeeeeeeeeeeeeeeeeeeeeeee444444999949444404411444ddeeeeeeeeeeeeeeeee442eeeeeeeeeeeeeeeeeeeeeeeeee
b333bb300bb3003b33b3333b33303333eeeeeeeeeeeeeeeeeeeeeeee4404949999444044044dd4446deeeeeeeeeeeeeee94422eeeeeeeeeeeeeeeeeeeeeeeeee
b30b333333333303333bb333b33333bbeeeeeeeeeeeeeeeeeeeeeeee4404999900094444444cd444d6eeeeeeeeeeeee9e9422223eeeeeeeeeeeeeeeeeeeeeeee
33b333333333b3333b3333333b333b33eeeeeeeeeeeeeeeeeeeeeeee4444494044494044494cc49466eeeeeeeeeeeee942b222b3eeeeeeeeeeeeeeeeeeeeeeee
bb3303b3033333003333b33b33b33333eeeeeeeeeeeeeeeeeeeeeeee00044940444900004447c49477eeeeeeeeeeeee422b322b34eeeeeeeeeeeeeeeeeeeeeee
3b3303b3003333333330033b30333303eeeeeeeeeeeeeeeeeeeeeeee49404944444044944007744466eeeeeeeeeeee4222b3333324ee4eeeeeeeeeeeeeeeeeee
b3300333b3303b3330333b333330333beeeeeeeeeeeeeeeeeeeeeeee444044444440449444477044ddeeeeeeeee944421313b3b3222224eeeeeeeeeeeeeeeeee
3b3333b33333330b3333b3303b33b333eeeeeeeeeeeeeeeeeeeeeeee444044444444444494417000ddeeeeeeeee4b33131313bb3333322224eeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee17ccdc70dd1c7c714440444400004444cd104444eeeeeeee442233331111113311131322244eeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee177cc773ccd77711000444444440404411044949eeeeeeeedddddd11dd11dd13bdddd11ddddddd7deeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1717c7107cc7171d440440404440444411444444eeeeeeeedddddddddddddddddddddddddd7dddddeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeed11171131771111d4400000049404040d0499444eeeeeeeed6d6776d6dddddddddddddddddddddddeeeeeeee
eeeee00eee00000eeeeeeeeeeeeeeeeeeeeeeeeed1d171d31171d1dc4404444044440000d0494444eeeeeeeeddddddddddddddddd666dddddddeeeeeeeeeeeee
ee000330ee0bbbb0eeeeeeeeeeeeeeeeeeeeeeeecddd1dc0111ddddc0004444000004440c0444444eeeeeeeeeeedddddd676ddd6666dddddddeeeeeeeeeeeeee
e00bbbb300bb3330eeeeeeeeeeeeeeeeeeeeeeeeccddddc01d1dcdd74440400440404490c0449494eeeeeeeeeeeedddddddddd6666ddedddeeeeeeeeeeeeeeee
e0bbbbbb0bb3000eeeeeeeeeeeeeeeeeeeeeeeee7ccddc70dd1dccd74440444444444444c0449444eeeeeeeeeeeeeeedddddd66ddddeeeeeeeeeeeeeeeeeeeee
e0003bbbbbb0bbb0eeeeeeeeeeeeeeeeeeeeeeee44404444404444404440444440444440704449444444444999494444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
03bbbb33bb0bbbbbeeeeeeeeeeeeeeeeeeeeeeee04044444444040400404444444404040704944444444494994444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00333bb000e00bbbeeeeeeeeeeeeeeeeeeeeeeee00004404444000000000440444400000704944444444494994444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0bb00b0eee0b30eeeeeeeeeeeeeeeeeeeeeeee04004444404000000400444440400000744444444444444999494444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee00bbb0eee0330eeeeeeeeeeeeeeeeeeeeeeee00000404000000000000040400000000100004444444444999444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeee0bbb30003300eeeeeeeeeeeeeeeeeeeeeeee000000a00a40000000000000004a0000d04044444444949499944444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00e0b3bb3bb000bbeeeeeeeeeeeeeeeeeeeeeeee00a0a4b00b0a0a000a0004a00a0a00a0c09444444444949499494444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bb00bb3b3bb0bbbbeeeeeeeeeeeeeeeeeeeeeeeeababbbbbbbbbbaba0b00b0a0ba0b00b0c94944444444949999494444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bbb3bbb33b0bbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
03bb3bbbbb000b00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
b03b3bbbb000e0bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bb033bb0000eee0beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
bb0bb00eee00000beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
b0000330ee0bbbb0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
000bbbb300bb3330eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e0bbbbbb0bb3000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0bbbb30bbb0bb0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0e0bbbb30bb0bbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
b0e0bb30e0b03bbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
b0e0bb0ee0b003bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
b0ee0b0eee0ee03beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0eee030eeeeee03beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0eeee0eeeeeeee03eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__gff__
0000000000000000000000000000000000000000000000000000808040000000000000434340000000008080400000004141414141414141414141414141414141414141414141414141212180808000414040414141414141410000808041414141414141414141414101018080818141414141414141414141000041418080
0000000000000000000000000000000000000000000000000000000000000000414141414500414040408080800100004141414100004140401000800080101041414141001010404010018080801010414141410041414040104141808080804040404043430000000080418080800041414141434300000000004040008000
