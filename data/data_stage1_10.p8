pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- picosonic data: pico island
-- region (1, 0) by leyn

-- Import latest spritesheet. Open data with pico8 -run for it to run automatically on launch.
import "spritesheet_stage_edition.png"

-- we only need __map__, but we kept __gfx__ only to visualize tiles when editing
-- (and __gff__ because it's not too big)
__gfx__
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00700700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00077000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00077000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00700700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeebbbb3bbbbbbbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeebbb303bbbb3bb0bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee3b300033b30b3003eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee0300400030030400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee4004444000000444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee4444444444004494eeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee4449444444044494eaeaeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee4449444444444444baebeebeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
49499444eeeeeeebbeeeeeee4444444494444444bb3bbbb33bbbbbbb0b30b30bb3bb03b03bbbb3bbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444449999494444
44949444eeeeeeabbaeeeeee4449444494944444bbbb3b300bb3b3b30030b00bb03b030003b3bbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444949999444444
49949944eeeeeeabbaeeeeee4444494444444444b3bb3b0403b333b040003003b003000440b3bb3beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4344999994494444
44949494eeeeeeb33beeeeee4444494994444444b33bbb0440303030440400403000404440bbb33beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4b34394999494444
44999944eeeeeebeebeeeeee44444449949444443003b304400000004444444004044444403b3003eeee999aaa7777a9eeeeeeeeeeeeeeee3bb4b94999994444
49994934eeeeeebeebeeeeee44449499994444440403300444040404444494440444444440033040eeee444999aa7aa9eeeeeeeeeeeeeeeebbbb3999999944b3
b39933b3eeeeeeeeeeeeeeee44449499494944444440304444444444444494444449444444030444eeee44999aa777a9eeeeeeeeeeeeeeeeb33bb939993b43bb
bb93bbbbeeeeeeeeeeeeeeee44449449494944444444004444444444444444444444444444004444eeeeeeedd766deeeeeeeeeeeeeeeeeeebb33b3b3393b3bbb
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee0eeeeeeee0444444444444444eeeeeeeeeeeeeed67dddeeeeeeeeeeeeeeeeeeeebb3b3bbbbb3bbb3b
40eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04eeeeeee4e04944444444944e4eeeeeeeeeeeed6ddeeeeeeeeeeeeeeeeeeeeeeeb3bb33bbb333bb3b
444eeeee4440eeeeeeeeeeeeeeeeeeeeeeee0044eeeee444eeeeeee4e04944444944440e4eeeeeeeeeeeee55dddeeeeeeeeeeeeeeeeeeeee03b3bbbbb3b3b3b0
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04444eeee0494eeeeee04ee044944449440ee40eeeeeeeeeeeee55ddddeeeeeeeeeeeeeeeeeeeb03bbb333bbbbbb0
44440eee4944400eeeeeeeeeeeeeeeaee0444944eee04494eeeeee04eee0444444940eee40eeeeeeeeeeeeeeeedd6deeeeeeeeeeeeeeeeeeb333bbbbb33b30bb
494944ee449444400eeeeeeeeeeeaea004444994ee449444eeeeee44eee0449444440eee40eeeeeeeeeeeeeeed77deeeeeeeeeeeeeeeeeeeb3bbb3bb30033bbb
4449440e44944944440eeeeeeeee303b44944494e0444494eeeee044eeee44944944eeee440eeeeeeeeeeeed77ddeeeeeeeeeeeeeeeeeeee3bb330bbbb3b33bb
444444404444444444440eeeebebbb3b4444444404444444eeeee044eeee04444440eeee444eeeeeeeeeeed6ddeeeeeeeeeeeeeeeeeeeeeebbbbb0bbb33bb3bb
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
eeeeeeeeeeeeeeeeeee77dded777deeeeeeeeeeeeeeeeeeeeeeeeeee444444499949444494494444eeeeeeee99000000eeeeeeeed6d949eeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeedd77d1dd777ddeeeeeeeeeeeeeeeeeeeeeeee0444449499444444494444444eeeeee99aa9000499eeeeeeed6d99aeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee7d1111dddd77d1eeeeeeeeeeeeeeeeeeeeeee00444449499444444499494444eeeee9aa9a94049aa9eeeeeed7d99aeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeed11111dddd7d111eeeeeeeeeeeeeeeeeeeeee00444444499949444499444944eeee9aa9aa94049aaa9eeeeed7da9aeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeee111117ddddd1111eaeeeeeeeeeeeeeeeeeee040444444499944444444444444eeee9a9aaa94049aaa9eeeeed7daa7eeeeeeeeeeeeeeeeee
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
eeeeeeeeeeeeeeeeeee5d5eeeeeeeeeeaaaaaaaaaaaaaaa9eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee30bbebe44444444ababb3bbbbb33bbbbeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeed65eeeeeeeeeaaaaaaaaaaaaaaa94eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3bebeeb349444444bba33bbbbabbb3333bbeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeed65eeeeeeee9a9a9a9a9a9aaa9940eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebeb33b3e44444494bbbbbbbbbbbabb33333bbeeeeeeeeeee
eeeeeeeeeeeeeeeeeeed65eeeeeee9a9a9a9a9a9aaa94400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb3e33eb44494444b3abba3bbbbbabb333333beeeeeeeeee
eeeea994eeeeeeeeeeed65eeeeee999999999999aa944400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee03bb03b44494444b00bb00bbbbbbbbbe33333beeeeeeeee
eeeaaaa94eeeeeeeeeed65eeeee99999999999aa99444000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3beb3ebe44444494b00bb00bbbbbbbab3333b33beeeeeeee
eeaaaaaaa999eeeeeeed65eeee9999999999aa9449444400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeb3b33eb3449444443b0330b33b3bbbbbb33bee3beeeeeeee
eaaaaaaaaaaa999eeeed65eee4949494999a944444444000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeebeebee444444440b0330b0eeebbebbbbeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeee949494449a99494444444440eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77778ee4444444444444444eeeeebbbbbeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeee99444449a9944444444444440eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7777788e0449449949944444eeeeeebbbbaeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeee44449a994444444444994440eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2288822e0449444994444000eeeeeeeebbbbeeeeeeeeeeee
eeeeeeeeeeeeeeeeee4499994444494444944494444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee28882ee4444444999444044eeeeeeeeebbbeeeeeeeeeeee
eeeeeeeeeeeeeeeea9994494499449444494444440eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee282eee0444499444444444eeeeeeeeebbbbeeeeeeeeeee
eeeeeeeeeeee99994494444444944444449444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2eeee0444444444444440eeeeeeeeeebbaeeeeeeeeeee
eeeeeeee44994494449444444494444444444400eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee004499440e004440eeeeeeeeeeebaeeeeeeeeeee
eeee44994444444444444444444444444440eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0049eeeeeee000eeeeeeeeeeeeeeeeeeeeeeeee
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000434340000000000000000000004141414141414141414141414141414141414141414141414141212180808000414040414141414141410000000041414141414141414141414101010000414141414141414141414141000041418080
0000000000000000000000000000000000000000000000000000000000000000414141414500414040408080800100004141414100004140401000800080101041414141001010404010018080801010414141410041414040104141808080804040404043430000000080418080800041414141434300000000004040008000
__map__
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6f6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e7e7f7e7f7e7f7e7f6e6f7e7f7e7f7e7f7e7f7e7f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e00000000000000007e7f000000000000000000006e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e00000000000000000000000000000000000000006e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f7f00000000000000000000000000000000000000006e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f0000000000000000000000000000000000000000006e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f0000000000000000000000000000000000000000006e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e49557e0000000000000000000000000000000000000000006e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
0000006f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e49557c7d00000000000000000000000000000000fa000000000059466e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
000000eaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaea7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7c7d0000000000000000000000000000000000000000000000007c7d59466e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e
000000eaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaea00000000000000000000000000000000000000000000000000000000000000000000000000000000000000ec000000000000007c7d6e6f6e6f6e7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e6e6f6e6f6e6f6e
000000eaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaea000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaabac00000000000000007e7f7e7f7e0000000000000000000000000000000000000000000000000000000000000000000000000000006e6f6e6f6e6f6e
000000eaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaeaea00000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006e6f6e6f6e6f6e
4246474847484748474847484748476f494344435556425852000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006e6f6e6f6e6f6e
ebeb59466e6f6e6f6e6f6e6f6f6e6f587c7d7c7d7c7d7c7d0000000000000000000000000000000000000000000000000000000000000000000000b0b1000000000000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000575857466e6f6e
7c7debeb59466e6e6f6e6f6e6f6e6f7d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c1000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007c7d7ceb575857
00007c7debeb59466f6e6f6e6f6e7e000000000000000000000000000000000000000000000000000000000000000000000000004c4d4d4c4e4d4ed0d14e4e4d4c4e4ecb4c4d4e0000000000000000b0b100000000b0b1000000000000000000000000000000000000000000000000000000000000000000000000007c7d7c7d
000000007c7d7c7d7e7f7e7f7e7f000000000000000000000000000000000000000000000000000000000000000000000000005141444441434346444644434649444143464546313335374d4d4c4dc0c14e4c4e4ec0c14d4c4e4e4e4c0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000b0b1000000000000000000000000000000000000000000000053545354535453545354535453545354535430594948484444494346464748494345414445424346463133353700000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000c0c1000000000000004c4e4c4d4e4d00000000000000000000dadbdadbdadbdadbdadbdadbdadbdadbdadb40535459585354535453545758535453545354535453545741424152000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000004e4ca0a14d4d4ed0d14e4c4e4c393a3b4945424346453c3d0000000000000000dadbdadbdadbdadb5e5f5e5f5e5f5e5f5e5f40dadb5354dadbdadbdadb5354dadbdadbdadbdadb7c7d7c7d7c7d00000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000514647494648484642434445444749455553545354535457463c3d000000000000dadbdadbdadb5e5f6e6f6e6f6e6f6e6f6e6f505e5f5e5f5e5f5e5fdadbdadbdadbdadbdadbdadb00000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000004e4d3839eb565354595553545354535455eb5354dadbdadbdadbdadb59463c3d4d4c4e4ddadbdadb5e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6fdadbdadbdadbdadbdadbdadb00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004c393a3b454547485354dadb5354dadbdadbdadb5354dadbdadbdadbdadbdadbdadb574646424643dadb5e5f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6fdadbdadbdadbdadbdadbdadb00000000000000000000000000000000000000000000000000000000000000000000000000
4d4ea0a1a0a14c4e4c393a3b4749455553545758dadb5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5fdadbdadbdadb5e5f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6fdadbdadb7c7ddadbdadb7c7d00000000000000000000000000000000000000000000000000000000000000000000000000
47484944454649464748455555eb5354dadb53545e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f5e5f5e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f7c7d7c7d0000dadb7c7d000000000000000000000000000000000000000000000000000000000000000000000000000000
5758535453545354595553545354dadbdadb5e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f0000000000007c7d0000000000000000000000000000000000000000000000000000000000000000000000000000000000
5354dadbdadbdadb5354dadbdadbdadb5e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6e6f6e6f6e6f6e6e6f6e6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6f7e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6e6f6e6f6e6f6e6e6f6e6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6f6e6f6e6e6f6e6f6e6f6e6e6f6e6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f6e7e7f7e7f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
