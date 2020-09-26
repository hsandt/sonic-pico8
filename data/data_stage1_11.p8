pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- this is a data cartridge which only contains map region data for:
-- Angel Island (1, 1)

-- we only need __map__, but we kept __gfx__ only to visualize tiles when editing
-- (and __gff__ because it's not too big)
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777700000000000000000000000000000000000000000000000000000000000000000000000000000000777777000000000000000000000000000077
00700700777777777777777700000000000000000000000000000000000000000000000000000000000000007777777777770000000000000000000000007777
00077000777777777777777777770000000000000000000000000000000000000000000000000000000077777777777777777700000000000000000000777777
00077000777777777777777777777777777777770000000000000000000000000000000000000000777777777777777777777777000000000000000077777777
00700700777777777777777777777777777777777777000000000000000000000000000000007777777777777777777777777777770000000000007777777777
00000000777777777777777777777777777777777777777777777777000000000000000077777777777777777777777777777777777700000000777777777777
00000000777777777777777777777777777777777777777777777777777700000000777777777777777777777777777777777777777777000077777777777777
70000000700000000000000000000000000000070000000700000007777777777777777770000000000000000000000000007777777777774444444999494444
77000000770000000000000000000000000000770000007700000007077777777777777070000000000000000000000000007777777777774444494994444444
77700000777700000000000000000000000077770000077700000007077777777777777070000000000077777777777700007777777777774444494994444444
77770000777770000000000000000000000777770000777700000077007777777777770077000000000077777777777700007777777777774444444999494444
77777000777777700000000000000000077777770007777700000077000777777777700077000000000077777777777700007777777777774444444999444444
77777700777777777000000000000007777777770077777700000077000777777777700077000000000077777777777700007777777777774444949499944444
77777770777777777770000000000777777777770777777700000777000077777777000077700000000077777777777700007777777777774444949499494444
77777777777777777777700000077777777777777777777700000777000077777777000077700000000077777777777700007777777777774444949999494444
7777777777777777777770000007777777777777777777770000777700000777777000007777000000000000000000770000000000000000e30bbebe44444444
77777770777777777770000000000777777777770777777700007777000007777770000077770000000000000000777700000000000000003bebeeb349444444
7777770077777777700000000000000777777777007777770007777700000077770000007777700000000000007777770000000000000000beb33b3e44444494
7777700077777770000000000000000007777777000777770007777700000077770000007777700000000077777777770000000000000000eb3e33eb44494444
7777000077777000000000000000000000077777000077770077777700000077770000007777770000007777777777770000777700000000e03bb03b44494444
77700000777700000000000000000000000077770000077707777777000000077000000077777770007777777777777700007777000000003beb3ebe44444494
7700000077000000000000000000000000000077000000770777777700000007700000007777777077777777777777770000777700000000b3b33eb344944444
7000000070000000000000000000000000000007000000077777777700000007700000007777777777777777777777770000777700000000eebeebee44444444
44444444eaeaeeeeeeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaebeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeee
44449444babaeabeeaeebeebeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeebaeabbbabbeeeeeeeeeeeeeeeeeeeeeeeeeaeab
44444494bbbababbbababbbbeebeeaeeeeeeeebeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeaeebbabab3babbbeaeeeeeeeeeeeeeeeeeeaeeebbab
44949444bbbbbbbbabbbbbbababbeaaeebeaeebeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeaaebbabbbbbbb3bbbbbbaeeeeeeeeeeeeeeeeeeaeabbbbb
44499444b3babbb3bbbbabbababbb3ababbababaeaeeeeaeeeeeaeeeeeeeeeeeeeeeeeeeeaeeeeaeba3bbbabbb3bab3bb3bababbeaeeeeeeeeeeeeaeabbab3bb
44949944b3bb3bb3bb3ba3bbb3bbb3b3b3bbbbbababaebaeeeaebeeaeeeeeeeeeeeeeeeeeabeababbb3bbbbbbb3bbbbbb3babbbbbaeaeeeeeeeeaeabbbbab3bb
44949944bbbb3bbbbb3bb3b3bbb3b3bbb3bb3bb3bbbabbabababbabbbaeeaeeeeeeaeeabbabbabbbbb3bbbbbbbbbbb3bb3bbb3bbbbbaeeaeeaeeabbbb3bbbb3b
44449444bb3bbbbb3bbbb3bbbbb3bbbbbbbb3bb3bb3abbbbbb3bbbbbbabaaeaeeaeaababbbbbabbbbbbb3b3bbbbbbbbbbbbbbbbb3ababbaeeabbaba3b3b3bb3b
44949444bbbbbbbbbbbbbbbbbbbb3bbbb3bbbbbbbbbbbb3bbbbbbb3bbababbabbabbababb3bbbbbbeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeee
44999444bb0bb3b3bb3bb0bbbbb303bbb3b3bb3bb3bb3b3bb3b3bbbbb3bbbbabbabbbbbbbbbb3b3beeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeee
449944443003b030b30b30033b300033bbbbbb3bb3bbbbbbbbb3bb3bb3bbbbbbbbbb3b3bb3bb3bbbeeee999aaa7777a9eeeeeeeeeeeeeeeeeeeeeeee5775eeee
49494944004030003003040003004000bbbb0bbbbbb0bbbb3bbbb33bbbbb3b3bbbbbbb3bb33bbbb3eeee444999aa7aa9eeeeeeeeeeeeeeeeeeeeeeee57775eee
44499444044400440000044440044440b03b03bbbb30b30b033b303bbbbbbb3bbb3bbbbbb303b330eeee44999aa777a9eeeeeeeeeeeeeeeeeeeeeeee577775ee
44999444444444444400449444444444000b00b03b00b00003033003bbbbbbbbbb3bbbbb30033030eeeeeeddddddddeeeeeeeeeeeeeaeeeeeeeeeaee57755eee
44994944444944444404449444494444040300300300304040003040b3b3bbbbbbbb3b3b30400000eeeeed66777766deeaeeeeaeeaeaeeaeeeaeaaee575eeeee
444949444444444444444444444944444440040000440444404004403bb3bb3bb3bb3bb304400404eeeeeeddddddddeeebeebeaebaebeebeeabeabebe5eeeeee
49499444eeeeeeebbeeeeeee4444444494444444bb3bbbb33bbbbbbb0b30b30bb3bb03b03bbbb3bbeeeeeeeeeeeeeeeeeeeeeeed71d7deee4444449999494444
44949444eeeeeeabbaeeeeee4449444494944444bbbb3b300bb3b3b30030b00bb03b030003b3bbbbeeeeeeeeeeeeeeeeeeeee1d7771dd1ee4444949999444444
49949944eeeeeeabbaeeeeee4444494444444444b3bb3b0403b333b040003003b003000440b3bb3beeeeeeeeeeeeeeeeeeeee11d7d0d111e4344999994494444
44949494eeeeeeb33beeeeee4444494994444444b33bbb0440303030440400403000404440bbb33beeeeeeeeeeeeeeeeeeeee177d100771e4b34394999494444
44999944eeeeeebeebeeeeee44444449949444443003b304400000004444444004044444403b3003eeee999aaa7777a9eeeed7777007777e3bb4b94999994444
49994934eeeeeebeebeeeeee44449499994444440403300444040404444494440444444440033040eeee444999aa7aa9eeeddd7710ddd711bbbb3999999944b3
b39933b3eeeeeeeeeeeeeeee44449499494944444440304444444444444494444449444444030444eeee44999aa777a9eeedddd110dddd11b33bb939993b43bb
bb93bbbbeeeeeeeeeeeeeeee44449449494944444444004444444444444444444444444444004444eeeeeeedd766deeeeeeddd11101d0110bb33b3b3393b3bbb
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee0eeeeeee404444444444444444eeeeeeeeeeeeed67dddeeeeeee1111171110000bb3b3bbbbb3bbb3b
40eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04eeeeeee4e04944444444944e4eeeeeeeeeeeed6ddeeeeeeeeee000ddd710770eb3bb33bbb333bb3b
444eeeee4440eeeeeeeeeeeeeeeeeeeeeeee0044eeeee444eeeeeee4e04944444944440e4eeeeeeeeeeeee55dddeeeeeeeee0dddd107777e03b3bbbbb3b3b3b0
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04444eeee0494eeeeee04ee044944449440ee40eeeeeeeeeeeee55ddddeeeeeee777111077777b03bbb333bbbbbb0
44440eee4944400eeeeeeeeeeeeeeeaee0444944eee04494eeeeee04eee0444444940eee40eeeeeeeeeeeeeeeedd6deeeeed7777100d7711b333bbbbb33b30bb
494944ee449444400eeeeeeeeeeeaea004444994ee449444eeeeee44eee0449444440eee40eeeeeeeeeeeeeeed77deeeeedddd7710dddd11b3bbb3bb30033bbb
4449440e44944944440eeeeeeeee303b44944494e0444494eeeee044eeee44944944eeee440eeeeeeeeeeeed77ddeeeeeeddddd110ddd1113bb330bbbb3b33bb
444444404444444444440eeeebebbb3b4444444404444444eeeee044eeee04444440eeee444eeeeeeeeeeed6ddeeeeeeeedddd11101d0110bbbbb0bbb33bb3bb
444444404444444444440eeeeee044444444444404444444eeee0444eeeee494440eeeee4440eeeeeee888eeeeeeeeee4444444444444444e3bbbbb3bbbb3bbe
4494440e44444444440eeeeeeeeee00494494444e0449494eeee4444eeeee044440eeeee4944eeeee7777788eeeeeeee0449444449444444eeba3b3e3bb3e3b3
449940ee499449400eeeeeeeeeeeeee044444944ee444494eee04494eeeeee4444eeeeee49440eee777777888eeeeeee0449494449444940e3b3e3ee3bb3eebb
44444eee4494440eeeeeeeeeeeeeeeeee0044994eee04444eee04494eeeeee0444eeeeee44440eee222888222eeeeeee4449494444444940ebb3eeeeeabbeea3
4940eeee44440eeeeeeeeeeeeeeeeeeeeee04494eeee0494ee044444eeeeee0440eeeeee494440eee2288822eeeeeeee0444494444440944ebbeeeeee3b3ee3e
440eeeee4400eeeeeeeeeeeeeeeeeeeeeeee0444eeeee444e0444494eeeeeee44eeeeeee4449440eee28882eeeeeeeee0044444400000440eabbeeeeee3eeeee
44eeeeee40eeeeeeeeeeeeeeeeeeeeeeeeeeee04eeeeee04e4449444eeeeeee44eeeeeee4949444eeee282eeeeeeeeee0000040000e00000ee3beeeeeeeeeeee
0eeeeeee0eeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeeee004444444eeeeeee44eeeeeee44444440eeee2eeeeeeeeeeee00000000ee00000eeebbeeeeeeeeeee
eeeeeeccceeeeeeeeeeeeeccceeeeeeeeeeeeccceeeeeeeeeeeeeeccceeeeeeeeeeeecccceeeeeeeeeeeecccceeeeeeeeeeeecccceeeeeeeeeeeeeecccceeeee
eeeeeccccceeceeeeeeeeccccceeceeeeeeeccccceeceeeeeeeeeccccceeceeeeeeecccccceceeeeeeeecccccceceeeeeeeecccccceceeeeeeeeeeeeccccceee
eeeeeecffcccceeeeeeeeecffcccceeeeeeeecffcccceeeeeeeeeecffcccceeeeeeeeeccfccceeeeeeeeeeccfccceeeeeeeeeeccfccceeeeeeeeeeeeccccccee
eeeeeccfcc7ccceeeeeeeccfcc7ccceeeeeeccfcc7ccceeeeeeeeccfcc7ccceeeeeeccccfc7cceeeeeeeccccfc7cceeeeeeeccccfc7cceeeee77eeccffccccce
eeeeccccc770cceeeeeeccccc770cceeeeeccccc770cceeeeeeeccccc770cceeeeeccccccc71ceeeeeeccccccc71ceeeeeeccccccc71ceeee7777cccfc7ccc77
eeecccccc770ceeeeeecccccc770ceeeeecccccc770ceeeeeeecccccc770ceeeeecccccccc70ceeeeecccccccc70ceeeeecccccccc70ceeeeee7ffccc707ccee
eeeeeeccff77f0eeeeeeeeccff77f0eeeeeeeccff77f0eeeeeeeeeccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeee7eecfccf07c67e
eeeeeccccfffeeeeeeeeeccccfffeeeeeeeeccccfffeeeeeeeeeeccccfffeeeeeeeecccc7fffeeeeeeeecccccff7eeeeeeeecccccfffeeeeeeeecccccffff0ee
eeeeccc99ccfeeeeeeeecffcff6eeeeeeeecffccfee56eeeeee777fccfeeeeeeeeeccc9777eeeeeeeeeccccffe777eeeeeeccccffee7eeeeeeeeeecf9effeeee
eeeeeeef77ff66eeeeeefeecffeeeeeee77feccff9966ee8ee7770ccff66eeeeeeeee9f07eeeeeeeee6ceccfff770eeeeeeceecffe777eeeeeeeeccffeeeeeee
eeeeeecc777f56eeeee770ccc7feeeee707ecccffeeeee88eee7ececff56eeeeeeeeecccf111eeeeee66ccccf1eeee20eee07ccccf770eeeeeeececcceeeeeee
eeeeeece0711eeeeeee777ec887eeeeee7eececcccc78780e002661cccee80eeeeeeececce61eeeeeeeececeee172700eee087eee1eeeeeeeeeeeeecceeeeeee
eeeeeeeeece1eeeeeeee7e260887eeeeee02611eeec7870e0262611ec78780eeeee87ccce0262eeeee86cceeee77200eeee088eeee16eeeeeeeeeee6ceeeeeee
eeeeeeeee7e7eeeeeeeee022000788eee02261eeeee8880e022eeeee78780eeeee088eeeee0222eee6886eeeeee200eeeeee078eee626220eeeeeee2ceeeeeee
eeeeeeeee878022eeeeee0022eee00ee062eeeeeeeee00eeeeeeeeee8870eeeeee0877eeeeee00eee860eeeeeee00eeeeeeee00eee02600eeeeeee06c7eeeeee
eeeeeeeee7888e22eeeeee00600eeeee22eeeeeeeeeeeeeeeeeeeeee000eeeeeeee08888eeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeee0277eeeeee
eeeeecccceeeeeeeeeeeeecccceeeeeeeeeeecccceeeeeeeeeeeeecccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0288eeeeee
eeeeeecffcceceeeeeeeecccccceceeeeeeeeecffcceceeeeeeeecccccceceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0870eeeee
eeeeeeecffccceeeeeeeeecffcccceeeeeeeeeecffccceeeeeeeeecffcccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee780eeeee
eeeeccccccc7cceeeeeeeccfccc7cceeeeeeccccccc7cceeeeeeeccfccc7cceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee080eeeee
eeeccccccc770ceeeeeecccccc770ceeeeeccccccc770ceeeeeecccccc770ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0eeeeee
eeeeeccccc770ceeeeeccccccc770ceeeeeeeccccc770ceeeeeccccccc770ceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeeeecccff77f0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeec9cc70cfffeeeeeee9c888cfffeeeeeec9cc702f2feeeeeee9cc70cfffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eee9ff77756e2eeeeee9f888856eeeeeeee9ff77752e22eeeee9ff777e6eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee7ecc77766220eeee228887766eeeeeeeee11777662222eee221177766eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e777cccff1e260eee22888cffeeeeee2ee87e11ffeee280ee228e11ffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
087cccece16220ee222ccee11eeee2e2088111ecccee780e22211eecceeeeee2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0888eeeee6820eee22eeeeee1eeee2220887eeeeeec7870e22eeeeeceeeee2e2eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
08878eeee8880eee2eeee871eeee222e08822eeeee7880ee2eeeee77eeee2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e07782eeee80eeeee2ee8877222222eee02222eeee8880eee2eee0887822222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ee0888222eeeeeeeeeee82227222eeeeee0222222ee80eeeeeeee08788822eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeccccceeeeeeeeeeecccceeeeeeeeeeeeccecceeeeeeeeeee2222eeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eecccccccceeeeeeeeccccccceeeeeeeeeceeccecceeeeeeee278227cceeeeeeeeeeee0e82eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eccccccc7cceeeeeeccccfccceeeeeeeececccccccceeeeee28777ccceceeeeeeeecccfee82eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eccccc777cceeeeecccccfc7cceeeeeeecccccccccceeeeee8ee777fcceeeeeeeccc007fe77eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ccccccc777cceeeececcccc70ceeeeee27cfcccccccceeee8eefffcccceceeeeccc7777f7782eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ccccccc7cccceeeeecccccc70ceeeeee22c7cfccffcceeeee0f77ffccccceeeeccccccff7722eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
cccccccccccceeeecccccff77f0eeeee2277ffcccccceeeeeec07cccccceeeeeccffccfc7c22eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
cccccccccccceeeececcccfffee8eeee2877f7777ccceeeeeec07ccccceceeeeccccccccfc72eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ccccccccccceeeeeeeccf777ee8eeeeee77ef700ccceeeeeeecc7cfccccceeeeecccccccccceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
ecccccccccceeeeeececcc77782eeeeee28eefccceeeeeeeeeecccfcccceeeeeecccccccceceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eecccccccceeeeeeeecc722872eeeeeeee28e0eeeeeeeeeeeeeccccccceeeeeeeeccecceeceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeecccceeeeeeeeeeee2222eeeeeeeeeeee8eeeeeeeeeeeeeeecccceeeeeeeeeeeccecceeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
__gff__
0041414141414141414141414141414141414141414141414141414141414141414141414141414141414141410080414141414141414141414141414141414141414141414141414141616180808000418080414141414141414040414141414545454343434343454541414141414145455149434343434545000041418080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d7e7f7e7f7e7f7e2e6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6f6f6e6f6e6f6e6f6e6f6e1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d6e6f6e6f6e6f6e6f6f584345436e6f6e1d1d1d1d1d1d1d1d6e6f1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2e0000001d1d0000000000001d1d00000000000000000000000000001d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000001d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5d00000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006c6d0000001d1d1d1d01030507000000000000000000005c5d000000000000005c
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5d0000006c6d0000001d1d1d1d1d1d1d1d010305070000000000006c6d000000000000006c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5d004c006c6d4c00006c6d0000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
4c4e00004e4c005c5d4e4c00004e4c5c5d4e4c4c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000042434649434646474848481d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
47484847484847484748484748474847484748471d1d01030507000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007c7d7c402f2f2f576e6f6e1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
43434455564346445556434649424146494241434141421d1d425200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000424146434242464642464643000000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
535453545354535354535453545354535453545e5f5f7d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066404071720000000073744040690000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
5e5f5e5f5e5f5e5e5f5e5f5e5f5e5f5e5f5e5f1d1d1d1d1d1d7d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000076407000000000000000007540790000000000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
6e6f6e6f6e6f6e6e6f6e6f6e6f6e6f6e6f1d1d1d7e7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040680000000000000000000067400000000000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040780000000000000000000077400000000000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000040000000000000000000001d1d1d1d1d1d1d1d1d1d1d
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d4c00004c00000000004a4b00000000000000000000000000000000000000004000000000000000000000000040000000000000000000001d1d1d1d1d1d1d1d1d1d1d
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d00000000000000000000000000000000000000000000000000000000000000000000000000000000000051434455434847311d1d1d1d1d1d1d1d1d1d1d1d1d3133353700000000000000000000676900000000000000000000666800000000000000000000000000001d1d1d1d1d0000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000305453544143411d1d1d1d1d1d1d1d1d1d1d1d1d5744444731333537000000000000777900000000000000000000767800000000000000000000000000001d1d1d1d1d0000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000301d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d4c5c53545359574444473133353700000075600000000000000000656800000000000000000000000000000000000000000000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0000000000000000000000000000000000000000000000000000000000000000000000004d4c0000004c4d4d481d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d4455401e545353545359574444473c3d00377561624c0000006364407800000000000000000000000000000000000000000000
00002e2e2e2e2e2e2e2e2e2e2e2e2e0000000000000000000000000000000000000000000000000000000000000000000000514344554348473147481d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d535453501e1f1e1f1e1f7e5354535957444447474955595854535453543c3d000000000000000000000000000000000000000000
00002e2e2e2e2e2e2e2e2e2e2e2e2e00000000000000000000000000000000000000000000000000000000000000004e4e4e4e5354535441434143481d1d1d1d1d1d1d1d1d1d1d1d1d1d1d561e1f1e1f1e1f1d1d1d1d1d1d1d1d1d535453595854535453541e1f1e1f59483c3d00000000000000000000000000000000000000
00002e2e2e2e2e2e2e2e2e2e2e2e2e5c5d000000000000000000000000000000000000000000000000000000003e3f474941491f1e1f1d1d1d1d1d481d1d1d1d1d1d1d1d1d1d1d1d1d301e1f1e1f1e5f1e1f1d1d1d1d1d1d1d1d1d1d1d1e1f1e1f1e1f1e1f1e1f1e1f405744593c3d0000000000000000000000000000000000
00002e2e2e2e2e2e2e2e2e2e2e2e2e6c6d00000000000000000000000000000000000000000000000000003e3f47495830301e1f1d481d1d1d1d1d481d1d1d1d1d1d1d1d1d1d1d1d1d401e1f1e1f1e6f5e5f1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d59483c3d000000000000000000000000000000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0103050700000000000000000000000000003e3f4845555354501d1d1d1d481d1d1d1d1d481d1d1d1d1d1d1d1d1d1d495830505e5f5e5f5e5f5e5f6e1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d405744420c0d00000000000000650000000000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d0103050700000000000000003e3f47495853541e1f1d1d1d1d1d481d1d1d1d1d48444748474848474845555354506f6e6f6e6f6e6f6e6f6e6f6e1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1e1f1e1f1d1d0c0d0000006364680000000000
1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d4845555354501d1d1d1d1d1d6f4848484747481d54305745555657445853541e1f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d780000000000
1d6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f1d1d1d1d1d1d1d1d1d1d1d1d6e6f6e6f6e6f6e5853541e1f1d1d1d1d1d1d1d6f5859434143444954305745555657445853541e1f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1f1e1f4057441d1d1d1d1d1d000000000000
6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6e6f6e6e6e48474558535453545354535453545354305745555657445853541e1f6e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f5e5f56464748474845555f5e5f50506e6f6e6f6e6f6e6f6e6f6e6f6e6f6e6f474848060606060606
