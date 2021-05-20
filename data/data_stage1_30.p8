pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- picosonic data: pico island
-- region (3, 0) by leyn

-- Import latest spritesheet. Open data with pico8 -run for it to run automatically on launch.
import "spritesheet_stage1_edition.png"

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
eeeeeeeeeeeeeeeeeeeeeeee4444444444004494eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee4449444444044494eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeee4449444444444444eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
49499444eeeeeeebbeeeeeee4444444494444444bb3bbbb33bbbbbbb0b30b30bb3bb03b03bbbb3bbeeeeeeeeeeeeeeeed7dd11ddd71eeeee4444449999494444
44949444eeeeeeabbaeeeeee4449444494944444bbbb3b300bb3b3b30030b00bb03b030003b3bbbbeeeeeeeeeeeeeeee777dd1ddd711eeee4444949999444444
49949944eeeeeeabbaeeeeee4444494444444444b3bb3b0403b333b040003003b003000440b3bb3beeeeeeeeeeeeeeee7777dd1d7d111eee4344999994494444
44949494eeeeeeb33beeeeee4444494994444444b33bbb0440303030440400403000404440bbb33beeeeeeeeeeeeeeeedd777dd0dd1111ee4b34394999494444
44999944eeeeeebeebeeeeee44444449949444443003b304400000004444444004044444403b3003eeee999aaa7777a9ddd7dd101111111e3bb4b94999994444
49994934eeeeeebeebeeeeee44449499994444440403300444040404444494440444444440033040eeee444999aa7aa9dd1dd1101ddd111ebbbb3999999944b3
b39933b3eeeeeeeeeeeeeeee44449499494944444440304444444444444494444449444444030444eeee44999aa777a97ddd1111dd77ddd1b33bb939993b43bb
bb93bbbbeeeeeeeeeeeeeeee44449449494944444444004444444444444444444444444444004444eeeeeeedd766deee77ddd0ddd7777dd1bb33b3b3393b3bbb
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee0eeeeeeee0444444444444444eeeeeeeeeeeeeed67dddeeee77ddd0ddddd7ddd1bb3b3bbbbb3bbb3b
40eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04eeeeeee4e04944444444944e4eeeeeeeeeeeed6ddeeeeeee777dd1ddddddd111b3bb33bbb333bb3b
444eeeee4440eeeeeeeeeeeeeeeeeeeeeeee0044eeeee444eeeeeee4e04944444944440e4eeeeeeeeeeeee55dddeeeee77dd11ddddd1111103b3bbbbb3b3b3b0
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04444eeee0494eeeeee04ee044944449440ee40eeeeeeeeeeeee55ddddeeedd11111ddd011111b03bbb333bbbbbb0
44440eee4944400eeeeeeeeeeeeeeeaee0444944eee04494eeeeee04eee0444444940eee40eeeeeeeeeeeeeeeedd6dee1111111ddd011111b333bbbbb33b30bb
494944ee449444400eeeeeeeeeeeaea004444994ee449444eeeeee44eee0449444440eee40eeeeeeeeeeeeeeed77deee1111111dd1011111b3bbb3bb30033bbb
4449440e44944944440eeeeeeeee303b44944494e0444494eeeee044eeee44944944eeee440eeeeeeeeeeeed77ddeeee11111011d10111103bb330bbbb3b33bb
444444404444444444440eeeebebbb3b4444444404444444eeeee044eeee04444440eeee444eeeeeeeeeeed6ddeeeeee111000011000000ebbbbb0bbb33bb3bb
444444404444444444440eeeeee044444444444404444444eeee0444eeeee494440eeeee4440eeee777ddd11111111114444444444444444e3bbbbb3bbbb3bbe
4494440e44444444440eeeeeeeeee00494494444e0449494eeee4444eeeee044440eeeee4944eeeedddddd11111111110449444449444444eeba3b3e3bb3e3b3
449940ee499449400eeeeeeeeeeeeee044444944ee444494eee04494eeeeee4444eeeeee49440eeeddddd111110111110449494449444940e3b3e3ee3bb3eebb
44444eee4494440eeeeeeeeeeeeeeeeee0044994eee04444eee04494eeeeee0444eeeeee44440eeedddd1111101111114449494444444940ebb3eeeeeabbeea3
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04494eeee0494ee044444eeeeee0440eeeeee494440eedddd1111001111110444494444440944ebbeeeeee3b3ee3e
440eeeee4400eeeeeeeeeeeeeeeeeeeeeeee0444eeeee444e0444494eeeeeee44eeeeeee4449440e1dd11110011111100044444400000440eabbeeeeee3eeeee
44eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04e4449444eeeeeee44eeeeeee4949444e11111100111111000000040000e00000ee3beeeeeeeeeeee
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee004444444eeeeeee44eeeeeee44444440000000000000000ee00000000ee00000eeebbeeeeeeeeeee
eeeeeeccceeeeeeeeeeeeccceeeeeeeeeeeeeccceeeeeeeeeeeeeeccceeeeeeeeeeecccceeeeeeeeeeeecccceeeeeeeeeeeecccceeeeeeeeeeeeeeecccceeeee
eeeeeccccceeceeeeeeeccccceeceeeeeeeeccccceeceeeeeeeeeccccceeceeeeeecccccceceeeeeeeecccccceceeeeeeeecccccceceeeeeeeeeeeeeccccceee
eeeeeecffcccceeeeeeeecffcccceeeeeeeeecffcccceeeeeeeeeecffcccceeeeeeeeccfccceeeeeeeeeeccfccceeeeeeeeeeccfccceeeeeeeeeeeeeccccccee
eeeeeccfcc7ccceeeeeeccfcc7ccceeeeeeeccfcc7ccceeeeeeeeccfcc7ccceeeeeccccfc7cceeeeeeeccccfc7cceeeeeeeccccfc7cceeeeee77eeccffccccce
eeeeccccc770cceeeeeccccc770cceeeeeeccccc770cceeeeeeeccccc770cceeeeccccccc71ceeeeeeccccccc71ceeeeeeccccccc71ceeeee7777cccfc7ccc77
eeecccccc770ceeeeecccccc770ceeeeeecccccc770ceeeeeeecccccc770ceeeecccccccc70ceeeeecccccccc70ceeeeecccccccc70ceeeeeee7ffccc707ccee
eeeeeeccff77f0eeeeeeeccff77f0eeeeeeeeccff77f0eeeeeeeeeccff77f0eeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeee7eecfccf07c67e
eeeeeccccfffeeeeeeeeccccfffeeeeeeeeeccccfffeeeeeeeeeeccccfffeeeeeeecccc7fffeeeeeeeecccccff7eeeeeeeecccccfffeeeeeeeeecccccffff0ee
eeeeccc99ccfeeeeeeecffcff6eeeeeeeeecffccfee56eeeeee777fccfeeeeeeeeccc9777eeeeeeeeeccccffe777eeeeeeccccffee7eeeeeeeeeeecf9effeeee
eeeeeeef77ff66eeeeefeecffeeeeeeee77feccff9966ee8ee7770ccff66eeeeeeee9f07eeeeeeeee6ceccfff770eeeeeeceecffe777eeeeeeeeeccffeeeeeee
eeeeeecc777f56eeee770ccc7feeeeee707ecccffeeeee88eee7ececff56eeeeeeeecccf111eeeeee66ccccf1eeee20eee07ccccf770eeeeeeeececcceeeeeee
eeeeeece0711eeeeee777ec887eeeeeee7eececcccc78780e002661cccee80eeeeeececce61eeeeeeeececeee172700eee087eee1eeeeeeeeeeeeeecceeeeeee
eeeeeeeeece1eeeeeee7e260887eeeeeee02611eeec7870e0262611ec78780eeee87ccce0262eeeee86cceeee77200eeee088eeee16eeeeeeeeeeee6ceeeeeee
eeeeeeeee7e7eeeeeeee022000788eeee02261eeeee8880e022eeeee78780eeee088eeeee0222eee6886eeeeee200eeeeee078eee626220eeeeeeee2ceeeeeee
eeeeeeee0878022eeeee0022eee00eee062eeeeeeeee00eeeeeeeeee8870eeeee0877eeeeee00eee860eeeeeee00eeeeeeee00eee02600eeeeeeee06c7eeeeee
eeeeeeee07888022eeeee00600eeeeee22eeeeeeeeeeeeeeeeeeeeee000eeeeeee08888eeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeee0277eeeeee
eeeeecccceeeeeeeeeeeeecccceeeeeeeeeeecccceeeeeeeeeeeeecccceeeeeeeeeeeeedeee11111eeeeeeee99000000eeeeeeeed6d949eeeeeeee0288eeeeee
eeeeeecffcceceeeeeeeecccccceceeeeeeeeecffcceceeeeeeeecccccceceeeeeeeedddeee11dddeeeeee99aa9000499eeeeeeed6d99aeeeeeeeee0870eeeee
eeeeeeecffccceeeeeeeeecffcccceeeeeeeeeecffccceeeeeeeeecffcccceeeeeeeedddeedddd77eeeee9aa9a94049aa9eeeeeed7d99aeeeeeeeeee780eeeee
eeeeccccccc7cceeeeeeeccfccc7cceeeeeeccccccc7cceeeeeeeccfccc7cceeeeeee1ddedddddd7eeee9aa9aa94049aaa9eeeeed7da9aeeeeeeeeee080eeeee
eeeccccccc770ceeeeeecccccc770ceeeeeccccccc770ceeeeeecccccc770ceeeeeee111edddddddeeee9a9aaa94049aaa9eeeeed7daa7eeeeeeeeeee0eeeeee
eeeeeccccc770ceeeeeccccccc770ceeeeeeeccccc770ceeeeeccccccc770ceeeeeee11dedddddd1eeee9a9aa994004999eeeeeed7d7a7eeeeeeeeeeeeeeeeee
eeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeee1ddeddd1d11eeeee99999403344eeeeeeeed6d777eeeeeeeeeeeeeeeeee
eeec9cc70cfffeeeeeee9c888cfffeeeeeec9cc702f2feeeeeee9cc70cfffeeeeeeeddd7e1d11111eeeeeeee449aa934eeeeeeeed6d7a7eeeeeeeeeeeeeeeeee
eee9ff77756e2eeeeee9f888856eeeeeeee9ff77752e22eeeee9ff777e6eeeeeeeeedd77ee1111111ddddddd49aaaa94eeeeeeeeeeeeeeee1110110111dd1111
ee7ecc77766220eeee228887766eeeeeeeee11777662222eee221177766eeeeeeeedddd7ee111117e1dddddd3bb99bb3eeeeeeeeeeeeeeeedd1111011ddddd11
e777cccff1e260eee22888cffeeeeee2ee87e11ffeee280ee228e11ffeeeeeeeeeddddddeee11d77e011dddd4b9aa9b4eeeeeeeeeeeeeeee7dd11101dddd77d1
087cccece16220ee222ccee11eeee2e2088111ecccee780e22211eecceeeeee2edddddddeeeed777ee1111dd4b9aa9b4eeeeeeeeeeeeeeeedd1110011ddddd11
0888eeeee6820eee22eeeeee1eeee2220887eeeeeec7870e22eeeeeceeeee2e2edddddddeeedd777eee1111d49aaaa94eeeeeeeeeeeeebbb1111101111dd1110
08878eeee8880eee2eeee871eeee222e08822eeeee7880ee2eeeee77eeee2222edddddddeedd7777eeee11113bb99bb3eeeeeeeeeeeebabb1111101101111000
e07782eeee80eeeee2ee8877222222eee02222eeee8880eee2eee0887822222eeddddd11eddd7777eeeee0114b9aa9b4eeeeeeeeeebbbbbe111100110110000e
ee0888222eeeeeeeeeee82227222eeeeee0222222ee80eeeeeeee08788822eeeed111111eddddd77eeeeee004b9aa9b4eeeeeeeeebbabbbe11100010000000ee
eeeecccceeeeeeeeeeeecccceeeeeeeeeeeeccecceeeeeeeeeee2222eeeeeeeeeeeeeee8eeeeeeeeee7a7d6d49aaaa94beeeeeeebaabbeee177011111ddd11ee
eecccccccceeeeeeeeccccccceeeeeeeeeceeccecceeeeeeee278227cceeeeeeeeeeee0e82eeeeeeee777d6d3bb99bb3bbeeeeebbbbbbbee7777d11dd777ddde
eccccccc7cceeeeeeccccfccceeeeeeeececccccccceeeeee28777ccceceeeeeeeecccfee82eeeeeee7a7d7d4b9449b4bbbeeebbabbbbbee77777ddd77777ddd
eccccc777cceeeeecccccfc7cceeeeeeecccccccccceeeeee8ee777fcceeeeeeeccc007fe77eeeeeee7aad7d49b44b94bbbbebbbbbbbbeee777777ddd77777dd
ccccccc777cceeeececcccc70ceeeeee27cfcccccccceeee8eefffcccceceeeeccc7777f7782eeeeeea9ad7d04bbbb40babbbbbbbb3eeeee7777777dddd7ddd1
ccccccc7cccceeeeecccccc70ceeeeee22c7cfccffcceeeee0f77ffccccceeeeccccccff7722eeeeeea99d7d049bb940bbabb3bbbbbbeeee777777771dddd111
cccccccccccceeeecccccff77f0eeeee2277ffcccccceeeeeec07cccccceeeeeccffccfc7c22eeeeeea99d6d00433400bbbbb33bebbeeeee7777777d11111101
cccccccccccceeeececcccfffee8eeee2877f7777ccceeeeeec07ccccceceeeeccccccccfc72eeeeee949d6d0a4334a0bbbabbbbbee33e3377777dd111110011
ecccccccccceeeeeeeccf777ee8eeeeee77ef700ccceeeeeeecc7cfccccceeeeecccccccccceeeee4444444999494444bbbbbbbbe333333333eebbbbbbeeeeee
ecccccccccceeeeeececcc77782eeeeee28eefccceeeeeeeeeecccfcccceeeeeecccccccceceeeee4444494994444444bbbbabbb33333bbbbbbbbbbaabbbeeee
eecccccccceeeeeeeecc722872eeeeeeee28e0eeeeeeeeeeeeeccccccceeeeeeeeccecceeceeeeee444449499444444433bbabbbbb3bbabbabbbbebbbbbbbeee
eeeecccceeeeeeeeeeee2222eeeeeeeeeeee8eeeeeeeeeeeeeeecccceeeeeeeeeeeccecceeeeeeee44444449994944443bbbb3bbbb3bbabbbbbbbbebbbbbbbee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444444999444444bb3bbbbbbabbbbbbbbebbbbbbbebbbbe
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444949499944444bb3bbb3bbbbbbbebbbbebbeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444949499494444abbbbb33bbbbbbbebbbbeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee4444949999494444bbbbbbbbbbbbb33eeeeeeeeeeeeeeeee
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
0041414141414141414141414141414141414141414141414141414141410000414141434341414141414141410000004141414141414141414141414141414141414141414141414141616180808000414040414141414141414040414141414141414141414141414141414141414141414141414141414141414141418080
0000000000000000000000000000000000000000000000000000000000000000000000000000000041418080800100000000000000000000414141800080414100000000000000000000018080804141000000000000000000004141808080804040404043430000000080418080800041414141434300000000004040008000
__map__
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f7e7f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
