pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- picosonic builtin data: stage_clear
-- by leyn

-- this section will be overwritten during build

-- Import latest spritesheet. Open data with pico8 -run for it to run automatically on launch.
-- Note that we don't need the collision masks for the stage clear sequence as Sonic is not visible,
--  so we just build with the stage clear spritesheet directly.
import "spritesheet_stage_clear.png"

-- the collision masks at the top will be overwritten by runtime sprites
--  via reload
__gfx__
00000000eeeeebbbeeeeeeeeeeeeeeeeeeed65eeeeeeeeeeeeeeeccccced65eeeeeeeeeee5eeeeeeeeeeeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeee8eeeeeeeeee
00000000eeeebbbeeeeeeeeeed66666666666666666666deed66cccccccc6666666666de575eeeeeee7eeeeeeeeee7eee272eeeeee2eeeeeeeee272eeeeee2ee
00700700eeebbbb7eeebeeee56000000000000000000006556000cc4ccccc0c0000000655775eeeeeed7eee87eee7dee877782eee272e2eeee287778ee2e272e
00077000eeeeeb77eebbbeee56ddd440dddddd4a0dd40d65569999cf4cccccc99999996557775eeeeee7ee8008ee7eeee272eeeeee2ee8eeeeee272eee8ee2ee
00077000eeebb3b7e777eeee56dd47a0d44404aaa047a06556999ccfccccccc995995965577775eeedd7780970877ddeee8ee2eeeeee272eee2ee8eee272eeee
00700700ebb7bb3bb3b7beee56d4aaa047aa4a7aa047a0655699ccccccccccc95759756557755eeeeedd78049087ddeeee2e272eee287778e272e2ee877782ee
00000000ebb77bbbb777bbee564aa0047aaaa700a04aa065569ccccc77cccc7c57757565575eeeeeeeedde8008eddeeeeeeee2eeeeee272eee2eeeeee272eeee
00000000eebb777777bbbbee564a0a04a004aa0d704aa06556ccccc7077cc07c95757565e5eeeeeeeeeeeee88eeeeeeeeeeeeeeeeeeee8eeeeeeeeeeee8eeeee
eeed6deeeb773777777bbeee564a0a70a0d4aaaa707a0d655cccccc70777707c95777565e00000ee333bbeeebbeeeeeebbeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee777eebb77bb37777eeeee564a00a0a447aa44ad7a006556999cc7077ff07c995775650eeeee0ebb3be3e33bbeeeee3bbeeeeeeeeeeeeeeeeeeeeeeeeeeee3
ee66666eeebbeebb777bb7bb560aaaa0aaaa0a00a0aaa0655699ccffffffff00557577550eeeee0e0bbeee3bbbb3eeeebbb3eeeeeeeeeeeeeeeeeeeeeeeeee3b
eed666deeeeeee77b777b7b756d0a0a00aa00a0da00000655699cccfffffff9957757755e0eee0eebb3eb3bb33b3eeee33b3eeeeeeeeeeeeeeeeeeeeeeee33bb
eed666deeeba77777777777756dd00a0d00d0a0da0dddd65569cccc9fffff99957566655ee0e0eee33bbbb3e03b33eee43b33eeeeeeeeeeeeeeeeeeeee337bba
eed666deebba77777777b77b56dddd0dddddd0dd00dddd65569cc9999999999995666655eee0eeeebbe3bbbe0333eeee4433eeeeeeeeeeeeeeeeeeee337abba7
eed666deebbb77777777bb775d77777777777777777777d55d7c777777777777775555d5eeeeeeee0b33bb3eb3bbb3eeb3bbb3eeeeeeeeeeeeeeee33abbbb7b3
eed666debbbba7777777bbbbe0000000000000000000000ee0000000000000000000000eeeeeeeeebbeeb3bb3bbb33ee4bbb33eeeeeeeeeeeeee337bbbb3b33e
eed666debbbb7a7777777777bbbb3bbbbbbbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbbb3eee33eb3bbe43eb3bbeeeeeeeeee333babbbb333eee
eed666de77b77777777777bbbbb303bbbb3bb0bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb3b33eee33e3bbbe33e3bbbeeeeeeee333b7bbbb3b33eeee
eed666debbba777777777ebb3b300033b30b3003eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb33eeeee333bb3ee333bb3eeeeeee33337bb3bb3333eeeee
eed666de7bbba7777777eeee0300400030030400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3333eeee033bb3ee443bb3eeeee333b33ab3bb3b33eeeeee
eed666dea7b7777777777bbe4004444000000444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebbb3eeee3b3e33b34b3e33b3ee33ab37bb33b3333eeeeeee
eed666debbbb77777b3377bb4444444444004494eeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee033eeeeeb333e333b333e333e33333333bbb3b33eeeeeeee
ee06660eebbe77b777bbbbeb4449444444044494eaeaeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee33beeeee33b3eeeb33b3eeebe33ab33a3b33333eeeeeeeee
eee000eeeebee77bebebeeee4449444444444444baebeebeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee33eeeeee03eeeeee43eeeeeeee33333333333eeeeeeeeeee
44444444eaeaeeeeeeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaebeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44449444babaeabeeaeebeebeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeebaeabbbabbeeeeeeeeeeeeeeeeeeeeeeeeeaeab
44444494bbbababbbababbbbeebeeaeeeeeeeebeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeaeebbabab3babbbeaeeeeeeeeeeeeeeeeeeaeeebbab
44949444bbbbbbbbabbbbbbababbeaaeebeaeebeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeaaebbabbbbbbb3bbbbbbaeeeeeeeeeeeeeeeeeeaeabbbbb
44499444b3babbb3bbbbabbababbb3ababbababaeaeeeeaeeeeeaeeeeeeeeeeeeeeeeeeeeaeeeeaeba3bbbabbb3bab3bb3bababbeaeeeeeeeeeeeeaeabbab3bb
44949944b3bb3bb3bb3ba3bbb3bbb3b3b3bbbbbababaebaeeeaebeeaeeeeeeeeeeeeeeeeeabeababbb3bbbbbbb3bbbbbb3babbbbbaeaeeeeeeeeaeabbbbab3bb
44949944bbbb3bbbbb3bb3b3bbb3b3bbb3bb3bb3bbbabbabababbabbbaeeaeeeeeeaeeabbabbabbbbb3bbbbbbbbbbb3bb3bbb3bbbbbaeeaeeaeeabbbb3bbbb3b
44449444bb3bbbbb3bbbb3bbbbb3bbbbbbbb3bb3bb3abbbbbb3bbbbbbabaaeaeeaeaababbbbbabbbbbbb3b3bbbbbbbbbbbbbbbbb3ababbaeeabbaba3b3b3bb3b
44949444bbbbbbbbbbbbbbbbbbbb3bbbb3bbbbbbbbbbbb3bbbbbbb3bbababbabbabbababb3bbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44999444bb0bb3b3bb3bb0bbbbb303bbb3b3bb3bb3bb3b3bb3b3bbbbb3bbbbabbabbbbbbbbbb3b3beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
449944443003b030b30b30033b300033bbbbbb3bb3bbbbbbbbb3bb3bb3bbbbbbbbbb3b3bb3bb3bbbeeee999aaa7777a9eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
49494944004030003003040003004000bbbb0bbbbbb0bbbb3bbbb33bbbbb3b3bbbbbbb3bb33bbbb3eeee444999aa7aa9eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44499444044400440000044440044440b03b03bbbb30b30b033b303bbbbbbb3bbb3bbbbbb303b330eeee44999aa777a9eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44999444444444444400449444444444000b00b03b00b00003033003bbbbbbbbbb3bbbbb30033030eeeeeeddddddddeeeeeeeeeeeeeaeeeeeeeeeaeeeeeeeeee
44994944444944444404449444494444040300300300304040003040b3b3bbbbbbbb3b3b30400000eeeeed66777766deeaeeeeaeeaeaeeaeeeaeaaeeeeeeeeee
444949444444444444444444444944444440040000440444404004403bb3bb3bb3bb3bb304400404eeeeeeddddddddeeebeebeaebaebeebeeabeabebeeeeeeee
49499444eeeeeeebbeeeeeee4444444494444444bb3bbbb33bbbbbbb0b30b30bb3bb03b03bbbb3bbeeeeeeeeeeeeeeeeeeebb333eeeeeebb4444449999494444
44949444eeeeeeabbaeeeeee4449444494944444bbbb3b300bb3b3b30030b00bb03b030003b3bbbbeeeeeeeeeeeeeeee3e3eb3bbeeeeebb34444949999444444
49949944eeeeeeabbaeeeeee4444494444444444b3bb3b0403b333b040003003b003000440b3bb3beeeeeeeeeeeeeeeeb3eeebb0eeee3bbb4344999994494444
44949494eeeeeeb33beeeeee4444494994444444b33bbb0440303030440400403000404440bbb33beeeeeeeeeeeeeeeebb3be3bbeeee3b334b34394999494444
44999944eeeeeebeebeeeeee44444449949444443003b304400000004444444004044444403b3003eeee999aaa7777a9e3bbbb33eee33b303bb4b94999994444
49994934eeeeeebeebeeeeee44449499994444440403300444040404444494440444444440033040eeee444999aa7aa9ebbb3ebbeeee3330bbbb3999999944b3
b39933b3eeeeeeeeeeeeeeee44449499494944444440304444444444444494444449444444030444eeee44999aa777a9e3bb33b0ee3bbb3bb33bb939993b43bb
bb93bbbbeeeeeeeeeeeeeeee44449449494944444444004444444444444444444444444444004444eeeeeeedd766deeebb3beebbee33bbb3bb33b3b3393b3bbb
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee0eeeeeeee0444444444444444eeeeeeeeeeeeeed67dddeeeeeee3bbbbebb3be33bb3b3bbbbb3bbb3b
40eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04eeeeeee4e04944444444944e4eeeeeeeeeeeed6ddeeeeeeeeee33b3bebbb3e33b3bb33bbb333bb3b
444eeeee4440eeeeeeeeeeeeeeeeeeeeeeee0044eeeee444eeeeeee4e04944444944440e4eeeeeeeeeeeee55dddeeeeeeeeee33bee3bb33303b3bbbbb3b3b3b0
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04444eeee0494eeeeee04ee044944449440ee40eeeeeeeeeeeee55ddddeeeeeee3333ee3bb330b03bbb333bbbbbb0
44440eee4944400eeeeeeeeeeeeeeeaee0444944eee04494eeeeee04eee0444444940eee40eeeeeeeeeeeeeeeedd6deeeeee3bbb3b33e3b3b333bbbbb33b30bb
494944ee449444400eeeeeeeeeeeaea004444994ee449444eeeeee44eee0449444440eee40eeeeeeeeeeeeeeed77deeeeeeee330333e333bb3bbb3bb30033bbb
4449440e44944944440eeeeeeeee303b44944494e0444494eeeee044eeee44944944eeee440eeeeeeeeeeeed77ddeeeeeeeeeb33beee3b333bb330bbbb3b33bb
444444404444444444440eeeebebbb3b4444444404444444eeeee044eeee04444440eeee444eeeeeeeeeeed6ddeeeeeeeeeeee33eeeeee30bbbbb0bbb33bb3bb
444444404444444444440eeeeee044444444444404444444eeee0444eeeee494440eeeee4440eeeeeeeeeeeeeeeeeeee4444444444444444e3bbbbb3bbbb3bbe
4494440e44444444440eeeeeeeeee00494494444e0449494eeee4444eeeee044440eeeee4944eeeeeeeeeeeeeeeeeeee0449444449444444eeba3b3e3bb3e3b3
449940ee499449400eeeeeeeeeeeeee044444944ee444494eee04494eeeeee4444eeeeee49440eeeeeeeeeeeeeeeeeee0449494449444940e3b3e3ee3bb3eebb
44444eee4494440eeeeeeeeeeeeeeeeee0044994eee04444eee04494eeeeee0444eeeeee44440eeeeeeeeeeeeeeeeeee4449494444444940ebb3eeeeeabbeea3
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04494eeee0494ee044444eeeeee0440eeeeee494440eeeeeeeeeeeeeeeeee0444494444440944ebbeeeeee3b3ee3e
440eeeee4400eeeeeeeeeeeeeeeeeeeeeeee0444eeeee444e0444494eeeeeee44eeeeeee4449440eeeeeeeeeeeeeeeee0044444400000440eabbeeeeee3eeeee
44eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04e4449444eeeeeee44eeeeeee4949444eeeeeeeeeeeeeeeee0000040000e00000ee3beeeeeeeeeeee
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee004444444eeeeeee44eeeeeee44444440eeeeeeeeeeeeeeeee00000000ee00000eeebbeeeeeeeeeee
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
eeeeeeeeeeeeeeeeeee77dded777deeeeeeeeeeeeeeeeeeeeeeeeeee444444499949444494494444eeeeeeee99000000eeeeeeeed6d949eeeeeeee0288eeeeee
eeeeeeeeeeeeeeeeeedd77d1dd777ddeeeeeeeeeeeeeeeeeeeeeeee0444449499444444494444444eeeeee99aa9000499eeeeeeed6d99aeeeeeeeee0870eeeee
eeeeeeeeeeeeeeeee7d1111dddd77d1eeeeeeeeeeeeeeeeeeeeeee00444449499444444499494444eeeee9aa9a94049aa9eeeeeed7d99aeeeeeeeeee780eeeee
eeeeeeeeeeeeeeeeed11111dddd7d111eeeeeeeeeeeeeeeeeeeeee00444444499949444499444944eeee9aa9aa94049aaa9eeeeed7da9aeeeeeeeeee080eeeee
eeeeeeeeeeeeeeeee111117ddddd1111eaeeeeeeeeeeeeeeeeeee040444444499944444444444444eeee9a9aaa94049aaa9eeeeed7daa7eeeeeeeeeee0eeeeee
eeeeeeaeeaeeeeeee111d777dddddd11baeaeeeeeeeeeeeeeeeee004444494949994444444004444eeee9a9aa994004999eeeeeed7d7a7eeeeeeeeeeeeeeeeee
eeaeaebeebeaeaeee11ddd77710d1111bbbaeeeeeeeeeeeeeeee0440444494949949444440000044eeeee99999403344eeeeeeeed6d777eeeeeeeeeeeeeeeeee
ababbbbbbbbbbabae0ddddd7111111113abbbaeeeeeeeeeeeeee0444444494999949444400000004eeeeeeee449aa934eeeeeeeed6d7a7eeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7dddddd1110110eeeeeeeeeeeeeeeeeeee04444444444999949444404411444eeeeeeee49aaaa94eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee1dd1dd107777ddeeeeeeeeeeeeeeeeeeee049444404949999444044044dd444eeeeeeee3bb99bb3eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee1d1ddd0dd7777deeeeeeeeeeeeeeeeeee0444444404999900094444444cd444eeeeeeee4b9aa9b4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee111d77dddd7777eeeeeeeeeeeeeeeeeee0444444444494044494044494cc494eeeeeeee4b9aa9b4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeedd7d11dd7eeeee11d777777d7777deeeeeeeeeeeeeeeee044949400044940444900004447c494eeeeeeee49aaaa94eeeeeeeeeeeeebbbeeeeeeeeeeeeeeee
eedd777ddd7d11eeeed77777777d7dddeeeeeeeeeeeeeeeee0449444494049444440449440077444eeeeeeee3bb99bb3eeeeeeeeeeeebabbeeeeeeeeeeeeeeee
ee1ddd77d0dd111eed77777777d1d111eeeeeeeeeeeeeeee04944444444044444440449444477044eeeeeeee4b9aa9b4eeeeeeeeeebbbbbeeeeeeeeeeeeeeeee
ee11dd7dd011111ed777777777111111eeeeeeeeeeeeeeee04444444444044444444444494417000eeeeeeee4b9aa9b4eeeeeeeeebbabbbeeeeeeeeeeeeeeeee
ee17dddd101dd11edd7777777d111111eeeeeeee17ccdc70dd1c7c714440444400004444cd104444ee7a7d6d49aaaa94beeeeeeebaabbeeeeeeeeeeeeeeeeeee
edd777dd0dd77dd1dddddddddd111111eeeeeeee177cc773ccd77711000444444440404411044949ee777d6d3bb99bb3bbeeeeebbbbbbbeeeeeeeeeeeeeeeeee
ddd7777d1ddddd11ddd1dddddd111111eeeeeeee1717c7107cc7171d440440404440444411444444ee7a7d7d4b9449b4bbbeeebbabbbbbeeeeeeeeeeeeeeeeee
dddd77d11ddd1111ddd7dddddd111110eeeeeeeed11171131771111d4400000049404040d0499444ee7aad7d49b44b94bbbbebbbbbbbbeeeeeeeeeeeeeeeeeee
dddddd111ddd1111ddd7dddddd111110eeeeeeeed1d171d31171d1dc4404444044440000d0494444eea9ad7d04bbbb40babbbbbbbb3eeeeeeeeeeeeeeeeeeeee
ddddd1111ddd1111ddddddddd111111eeeeeeeeecddd1dc0111ddddc0004444000004440c0444444eea99d7d049bb940bbabb3bbbbbbeeeeeeeeeeeeeeeeeeee
ddddd11111d11110ddddddddd111101eeeeeeeeeccddddc01d1dcdd74440400440404490c0449494eea99d6d00433400bbbbb33bebbeeeeeeeeeeeeeeeeeeeee
111d11110110110eddddddddd111101eeeeeeeee7ccddc70dd1dccd74440444444444444c0449444ee949d6d0a4334a0bbbabbbbbee33e33eeeeeeeeeeeeeeee
e1111dd10dd777dedddddddd1111101eeeeeeeee44404444404444404440444440444440704449444444444999494444bbbbbbbbe333333333eebbbbbbeeeeee
ee11d77ddd77777ddddddddd11111011eeeeeeee04044444444040400404444444404040704944444444494994444444bbbbabbb33333bbbbbbbbbbaabbbeeee
ee1d7777ddd7777d1ddddddd11111111eeeeeeee0000440444400000000044044440000070494444444449499444444433bbabbbbb3bbabbabbbbebbbbbbbeee
eedd777d10dddd1101dddddd11111111eeeeeeee040044444040000004004444404000007444444444444449994944443bbbb3bbbb3bbabbbbbbbbebbbbbbbee
edddd7dd10ddd111e111dddd11110111eeeeeeee00000404000000000000040400000000100004444444444999444444bb3bbbbbbabbbbbbbbebbbbbbbebbbbe
dddddd1110ddd111e111ddd111100111eeeeeeee000000a00a40000000000000004a0000d04044444444949499944444bb3bbb3bbbbbbbebbbbebbeeeeeeeeee
ddddd11110dd1111eee0111111011110eeeeeeee00a0a4b00b0a0a000a0004a00a0a00a0c09444444444949499494444abbbbb33bbbbbbbebbbbeeeeeeeeeeee
dd1111110011011eeeee00000000000eeeeeeeeeababbbbbbbbbbaba0b00b0a0ba0b00b0c94944444444949999494444bbbbbbbbbbbbb33eeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeee5d5eeeeeeeeeeaaaaaaaaaaaaaaa9eeeeee56deeeeeeeeeeeeeed65eeeeeee30bbebe44444444ababb3bbbbb33bbbbeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeed65eeeeeeeeeaaaaaaaaaaaaaaa94ed6566666666666ee6666666666656de3bebeeb349444444bba33bbbbabbb3333bbeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeed65eeeeeeee9a9a9a9a9a9aaa9940d656000000000005500000000000656dbeb33b3e44444494bbbbbbbbbbbabb33333bbeeeeeeeeeee
eeeeeeeeeeeeeeeeeeed65eeeeeee9a9a9a9a9a9aaa94400d656d944dc49d91551d944dc49d9656deb3e33eb44494444b3abba3bbbbbabb333333beeeeeeeeee
eeeea994eeeeeeeeeeed65eeeeee999999999999aa944400d65694cdc0ca9a155194cdc0ca9a656de03bb03b44494444b00bb00bbbbbbbbbe33333beeeeeeeee
eeeaaaa94eeeeeeeeeed65eeeee99999999999aa99444000d656dcacac75471551dcacac7547656d3beb3ebe44444494b00bb00bbbbbbbab3333b33beeeeeeee
eeaaaaaaa999eeeeeeed65eeee9999999999aa9449444400d6569ac7ca7a7a15519ac7ca7a7a656db3b33eb3449444443b0330b33b3bbbbbb33bee3beeeeeeee
eaaaaaaaaaaa999eeeed65eee4949494999a944444444000d6564c000c094715514c000c0947656deebeebee444444440b0330b0eeebbebbbbeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeee949494449a99494444444440ed656c0ca7a77701551c0ca7a7770656de77778ee4444444444444444eeeeebbbbbeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeee99444449a9944444444444440eed65649a04f4977155149a04f4977656d7777788e0449449949944444eeeeeebbbbaeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeee44449a994444444444994440eeeed6569afaf00a7a15519afaf00a7a656d2288822e0449444994444000eeeeeeeebbbbeeeeeeeeeeee
eeeeeeeeeeeeeeeeee4499994444494444944494444eeeeed656dcafaf05071551dcafaf0507656de28882ee4444444999444044eeeeeeeeebbbeeeeeeeeeeee
eeeeeeeeeeeeeeeea9994494499449444494444440eeeeeed65690cdf09a5d155190cdf09a5d656dee282eee0444499444444444eeeeeeeeebbbbeeeeeeeeeee
eeeeeeeeeeee99994494444444944444449444444eeeeeeed656dc09d9d9d61551dc09d9d9d6656deee2eeee0444444444444440eeeeeeeeeebbaeeeeeeeeeee
eeeeeeee44994494449444444494444444444400eeeeeeeed60d777777777775577777777777d06deeeeeeee004499440e004440eeeeeeeeeeebaeeeeeeeeeee
eeee44994444444444444444444444444440eeeeeeeeeeeeed6000000000000ee0000000000006deeeeeeeeee0049eeeeeee000eeeeeeeeeeeeeeeeeeeeeeeee
__gff__
0000000000000000000000000000000000000000000000000000808040000000000000434340000000008080400000004141414141414141414141414141414141414141414141414141212180808000414040414141414141410000808041414141414141414141414101018080818141414141414141414141000041418080
0000000000000000000000000000000000000000000000000000000000000000414141414500414040408080800100004141414100004140401000800080101041414141001010404010018080801010414141410041414040104141808080804040404043430000000080418080800041414141434300000000004040008000
__map__
000000000000000000006e6f6e6f6e6f6e6f6f6e6f6e6f6e6f6e6f6e6f6e49466e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f497e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f000000000000000000007c7d7c7d7c7d7c7d1e1f1e1f1e1f1e1f5e5f5e5f5f
000000000000000000006e6f6e6f6e6f6e6f6f585945434443454244455554307e7f7e7f7e7f7e7f7e7f7e7f7e2e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6f6f6e6f6e6f6e6f6e6f6e6f44417000000000000000000000000000000000000000000000000000000000000000000000000000007c7d5e5f5e5f5e5f6e6f6e6f6f
000000000000000000006e6f6e6f6e6f6e6f6f7c7d7c7d535453545354531f40000000000000000000000000002e6e6f6e6f6e6f6e6f6f584345436e6f6e6f6e6f6e6f6e6e6f6e6f6e6f520000000000000000000000000000000000000000000000000000000000000000000000000000000000516e6f6e6f6e6f7e7f7e7f7f
000000000000000000006e6f6e6f6e6f6e6f6f2e0000001e1f1e1f1e1f1e1f504d4e7a4c4e00000000000000000057464344464344425853547c7d002e2e2e6e6f6e6f6e6f2e2e2e2e2e000000000000000000000000000000000000000000000000000000000000000000000000000000000000007e7f7e7f7e7f0000000000
000000000000000000006e6f6e6f6e6f6e6f6e2e0000005e5f5e5f5e5f5e5f6e48454645415200000000000000002f2f2f2f2f2f2f2f307d70000000002e2e2e2e2e2e2e2e2e000000000000000000000000000000007a0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000006e6f6e6f6e6f6e6f6e2e0000516e6f6e6f6e6f6e6f49582f2f2f7d0000004d4c000000002f2f2f2f2f2f2f2f70000000000000002e2e2e2e2e2e2e000000000000000000000000000000005c5d0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000006e6f6e6f6e6f6e6f6f2e0000007e7f7f7e7e7f6f582f2f2f2f7d000000514342520000007c7d2f2f7c7d7c7d000000000000000000000000000000000000000000004e4d4d4c4d4e5c5d4e6c6d4d00000000000000000000000000004d4e7a4c4d00000000000000004e4e4c4d4e4c4d4d4c00000000
000000000000000000006e6f6e6f6e6f6e6f6f2e0000000000000000007f7c7c7d7c7d00000000007c7d0000000000007c7d00000000000000000000000000000000000000000000000000514241424441564146424445483c3d0000000000000000000000514344454943520000000000005142414643424246464352000000
000000000000000000006e6f6e6f6e6f6e6f6f2e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000535453545354535453542f5759425200000000000000000000005354305354000000000000000040407172007374404000000000
000000000000000000006e6f6e6f6e4543444352000000000000000000000000000000000000000000000000000000000000000000000000004d4e000000004d4e4d38393434343d000000001e1f1e1f1e1f1e1f1e1f5e5f7c7d000000000000000000000000757c7d7c70000000000000000040680000000000674000000000
000000000000000000004542444558535453544c4e7a4d4c4d000000000000000000000000000000000000000000000000000000004e4d4c5147493132323b4745444644454342463c3d4d4c1e1f1e1f1e1f1e1f5e5f6e6f00000000000000000000000000000000000000000000000000000040780000000000774000000000
0000000000000000000030535453541e1f1e1f5642454344555200000000000000000000000000000000004d4d000000004c393a3b49444644555357454442585354535453545354594542561e1f1e1f5e5f5e5f6e6f7f7e00000000000000000000000000000000000000000000000000000040000000000000004000000000
00000000000000000000401e1f1e1f1e1f1e1f535453545354004d4e00000000000000000000000000005143463132323b4749455554535453545354535453541e1f1e1f1e1f1e1f1e1f1e1f5e5f5e5f6e6f6e6f7e7f000000000000000000000000000000000000000000000000000000000067690000000000664000000000
00000000000000000000401e1f1e1f1e1f1e1f1e1f1e1f7c7d514142520000000000000000000000000000535459454542555354531f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f5e5f6e6f6e6f7f7e7f7e0000000000000000000000000000000000000000000000000000000000000077790000000000766800000000
000000000000000000007c7d7c7d7c7d7c7d1f1e1f1e7d0000007c7d0000000000000000000000000000007c2f53545354301e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f1e1f5e5f6e6f7f7e7e7f00000000000000000000005c5d00004d4c000000000000000000000000000051313335377561624c6364407800000000
0000000000000000000000000000000000007c1e1f7d000000000000000000000000000000004e4d000000007c5e5f5e5f505e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f6e6f7f7e0000000000000000000000005c5d006c6d005143463c3d000000005c5d0000000000000057444447474955595854533c3d000000
000000000000000000000000000000000000007c7d0000000000000000000000000000000051424152000000006e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f7e7f000000000000000000004c5c5d4e6c6d4c6c6d4c4e1e1f59483c3d00006c6d00000000000000535453595854535453544059483c3d4c
00000000000000000000000000000000000000000000000000000000000000000000000000007c7d00000000007e7e7f7e7f7e7f7e7f7f7e7e7e7f7e7e7f7f7e7f7e7e7f7e7f7e7f00000000000000000000005142434649434646474848481e1f1e57594546434549434631330000001e1f1e1f1e1f1e1f1e1f404057444243
00000000000000000000000000000000000000000000000000000000000000004a4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d4c00007c7d7c402f2f2f576e6f6e5e5f5e5f5e5f5e5f5e5f5e5f57555200005e5f5e5f5e5f5e5f5e5f50505e5f5e5f
0000000000000000000000000000000000000000000000000000000000000051434252000000000000000000000000000000000000000000000000000000000000000000000000000000000000000051434152000000004071727374596e6f6e6f6e6f6e6f6e6f6e6f6e6f7c7d0000516e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f
00000000000000000000000000000000000000000000000000000000000000007c7d000000000000000000000000004c4e5c5d4e4c5c5d4e4c4c000000000000000000000000000000000000000000007c7d00000000006800000000677e7f7f7e7f7f7e7e7e7f7e7f7e7f00000000002e2e2e2e2e2e2e2e2e2e2e2e6e6f6e6f
00000000000000000000000000000000000000000000000000000000000000000000000000000000004e4c38393a3b47484847484847484748473133000000000000000000000000000000000000000000000000000000780000000077000000000000000000000000000000000000000000000000000000000000002e2e2e2e
00000000000000000000000000000000000000000000000000000000000000000000000000000000514346474849414343445556434649424143414252000000000000000000000000000000000000000000000000000069000000006600000000000000000000000000000000000000000000000000000000000000002e2e2e
00000000000000000000000000004c4e0000000000000000000000000000004c4c4e4d4a4b4e4d4c4d535457585354535453545354535453545e5f7d000000000000000000000000000000004d4c5c5d4e4d4e000000007900000000760000000000000000000000000000000000004e4c000000000000000000000000002e2e
4d000000004c0000000038393a3b45463c3d00000000000000000000000066564142434142414346555e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f6e6f0000000000000000000000000000000051434455434441463133353740616263644000000000000000000000000000000000005144463c3d0000000000000000000000002e
483132323b473132323b45424155535457463c3d000000000000000000007653545354535453545e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f7f7e00000000000000000000000000004e4e4d53545354535430574447474748495853543c3d00000000006570000000000000000000535457463c3d4d4e5c5d00004d4e4c4e4c
41434649414243444558535453541e1f535457443c3d0000000000000065401e1f1e1f1e1f5e5f6e6f6e6f7e7f7e7f7e7f2e2e2e2e2e2e2e2e000000000000000000000000000000514149561e1f1e1f1e1f40301e5945445854401e1f42463c3d4d636470000000000000000000001e1f535459434245424152514441454645
535453545354535453541e1f1e1f1e1f1e1f535459463c3d000000636440401e1f1e1f5e5f6e6f6e6f6e6f0000000000002e2e2e2e2e2e2e2e00000000000000000000000000004e4e301e1f1e1f1e1f1e1f40401e545354531f505e5f5e5f59454455700000004c4e4d4c4d4e4a4b1e1f1e1f535430307c7d00003053545354
5e5f5e5f5e5f5e5f5e5f5e5f5e5f1e1f1e1f5e5f53545741424341584050505e5f5e5f6e6f6e6f6e6f6e6f00000000004d2e2e2e2e2e2e2e2e4d00000000000000000000003e3f4749401e1f1e1f1e1f1e1f50501e1f1e1f1e1f7e7f7e7f7e000000000000006556444246555644451e1f1e1f1e1f407d00000000401e1f1e1f
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f535453545354506e6f6e6f6e6f6e6f6e6f6e6f6e6f00007a005148474748484748474748313335374e4d4c4d4c3e3f47495830505e5f5e5f5e5f5e5f6e6f5e5f1e1f1e1f000000000000004d4c4d63643053545354535453541e1f1e1f1e1f400000000000401e1f1e1f
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f5e5f5e5f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f3536373839495857555859434143444946444748474848474845555354506f6e6f6e6f6e6f6e6f6e6f6e6f5e5f1e1f4d4c7a4e4d3e3f4749445530405e5f5e5f5e5f5e5f5e5f5e5f5e5f504e7a4d3e3f505e5f5e5f
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6e6e48474558535453545354535453545354305745555657445853541e1f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f56464748474845555f5e5f50506e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f47484849466e6f6e6f
__sfx__
011000003005032050300503205030050320503005032050300503205030050320503005032050300503205030050320503005032050300503205030050320503005032050300503205030050320503005032050
010c00001835018350183501835018350183501835018350183501835018350183501835018350183501835018350183501835018350183501835018350183501835018350183501835018350183501835018350
000a0000326203c610346202b630206301c620226102f62037630326302b6202461021620286203463030630376203162033610296202f6300060000600006000060000600006000060000600006000060000600
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001a1351a1351a1351a135000001a135000001c135000001c135000001c135000001c1301c1301c1351f1301f1350000021130211350000024130241350000026130261302613026130261302613026130
010e0000131351313513135131350000013135000001513500000151350000015135000001513015130151351813018135000001a1301a135000001d1301d135000001f1301f1301f1301f1301f1301f1301f130
010e00002613026130261302613026130261302613026130261302613026130261302613026130261302613026130261302613500000000000000000000000000000000000000000000000000000000000000000
010e00001f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f1301f13500000000000000000000000000000000000000000000000000000000000000000
0107000015645156050c6450c6050c6450c60515645156050c6450c6050c6450c60515645156050c6450c60515645156050c6450c60515645156050c6450c6050c6450c6050c6450c605156450c645156450c645
010e00000000000000000000000000000000000000000000000000000000000000000000000000000000000015635116351763515635116351763515635116351763515635156001560015600156001560015605
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002d8502d800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000027a102da3031a4034a5037a503aa503aa5039a5038a5036a5031a402ca4024a401fa401ba3017a3014a3011a200ea200da200ba1009a1008a1007a1006a1005a1004a1003a1003a1003a1003a0000a00
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e000024755267552875526755280502975528050297552b050290502f050300503004030030300203001500000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 08090c0d
04 0a0b4040
