pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- picosonic builtin data: titlemenu
-- by leyn

-- Import latest spritesheet. Open data with pico8 -run for it to run automatically on launch.
import "spritesheet_titlemenu.png"

-- this section will be overwritten during build
__gfx__
00000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeeee77778eeeeeeeeeeee8eeeeeeeeeeeeeeeeee8eeeeeeeeee
00000000ee7eeeeeeeeee7eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeee7777788eeeeeeeeee272eeeeee2eeeeeeeee272eeeeee2ee
00700700eed7eee87eee7deeeeeeeee0000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5775eeee2288822eeeeeeeee877782eee272e2eeee287778ee2e272e
00077000eee7ee8008ee7eeeeeeeee0222700eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee57775eeee28882eeeeeeeeeee272eeeeee2ee8eeeeee272eee8ee2ee
00077000edd7780970877ddeeeeee028887720eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee577775eeee282eeeeeeeeeeeee8ee2eeeeee272eee2ee8eee272eeee
00700700eedd78049087ddeeeeeee0888877820eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee57755eeeeee2eeeeeeeeeeeeee2e272eee287778e272e2ee877782ee
00000000eeedde8008eddeeeeeeee0000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee575eeeeeeeeeeeeeeeeeeeeeeeeee2eeeeee272eee2eeeeee272eeee
00000000eeeeeee88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee5eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8eeeeeeeeeeee8eeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1d77777777d1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1d7777dddddddd7777d1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1d77dd111111111111dd77d1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1d777d111144444444441111d777d1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
e1d1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1d7d1114919aaaaaaaaaa9194111d7d1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1d1eeeeeeecccceeeeee
e1d7dd1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1d711144901110aaaaaaaa011109441117d1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee1dd7d1eeeeeecccccceceee
e0dd777dd1eeeeeeeeeeeeeeeeeeeeeeeeeeed7d11499aaa101aaaaaaaaaa101aaa99411d7deeeeeeeeeeeeeeeeeeeeeeeeeee1dd777dd0eeeeeeecffcccceee
ee1d777777dd1eeeeeeeeeeeeeeeeeeeeee11d1144aaaaaa0a0aaaaaaaaaa0a0aaaaaa4411d11eeeeeeeeeeeeeeeeeeeeee1dd777777d1eeeeeeeccfccc7ccee
eee1d77777777dd1eeeeeeeeeeeeeeeeee1dd1149aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9411dd1eeeeeeeeeeeeeeeeee1dd77777777d1eeeeeeecccccc770cee
eee0dd77777777777dd1eeeeeeeeeeeee1dd1491aaaaaaaaaaa1d7d77d7d1aaaaaaaaaaa1941dd1eeeeeeeeeeeee1dd77777777777dd0eeeeeeccccccc770cee
eeee0dd77777777777777dd1eeeeeeee1d11401110aaaaaad17dddddddddd71daaaaaa01110411d1eeeeeeee1dd77777777777777dd0eeeeeeeeeecccff77f0e
eeeee1dd77777777777777777dd1eee1d114aa101aaaa1d1ddd1111111111ddd1d1aaaa101aa411d1eee1dd77777777777777777dd1eeeeeeeee9c888cfffeee
eeeeee0dd7777777777777777777771dd14aaa0a0aaa7ddd1110000000000111ddd7aaa0a0aaa41dd1777777777777777777777dd0eeeeeeeee9f888856eeeee
eeeeeee1dd7777777777777777777d1d14aaaaaaaa11dd11000000000000000011dd11aaaaaaaa41d1d7777777777777777777dd1eeeeeeeee228887766eeeee
eeeeeeee01d77777777777777777d1d14aaaaaaaa1dd110000000000000000000011dd1aaaaaaaa41d1d77777777777777777d10eeeeeeeee22888cffeeeeee2
eeeeeeeee10d77777777777777771d11aaaaaaaa1dd10000000000000000000000001dd1aaaaaaaa11d17777777777777777d01eeeeeeeee222ccee11eeee2e2
e11eeeeeeee1dd7777777777777d1d19aaaaaaa1dd1000000000000000000000000001dd1aaaaaaa91d1d7777777777777dd1eeeeeeee11e22eeeeee1eeee222
e1dd10eeeeee10dd777777777771d140000000000000000000000000000000000000000000001aa1a41d177777777777dd01eeeeee01dd1e2eeee871eeee222e
ee1d77d10eeeee1ddd777777771dd100111111111111000111111100011111111000100499941011101dd177777777ddd1eeeee01d77d1eee2ee8877222222ee
ee0dd7777d10eee01ddd7777771d19a019777aaaa9941001977aa100104aaa99991104a7aaaa94011a91d1777777ddd10eee01d7777dd0eeeeee82227222eeee
eee1d77777771100000dd7777d1d1aa019799999999941019a999111097a9999991097a99999aa900aa1d1d7777dd00000117777777d1eeeeeeeeeeeeeeeeeee
eee0dd77777777777777777771d19aa019799999999991019a9991109799999990047a99999999940aa91d17777777777777777777dd0eeeeeeeeeeeeeeeeeee
eeee0dd7777777777777777771d1aaa019799911199994119a999109799999999109a9999999999910aa1d1777777777777777777dd0eeeeeeeeeeeeeeeeeeee
eeeee1d777777777777777771d11aaa01979991110a999119a99910a99999119400a99999119999910aa11d177777777777777777d1eeeeeeeeeeeeeeeeeeeee
eeeeee1d77777777777777771d1aaaa019a9991110a994119a99914a99991111104a999911109999410aa1d17777777777777777d1eeeeeeeeeeeeeeeeeeeeee
eeeeee0dd7777777777777771d1aaaa019a9990007a991019a99919a99911111109a99911110a999910aa1d1777777777777777dd0eeeeeeeeeeeeeeeeeeeeee
eeeeeee0dd777777777777771d1aaaa019a999aa7a9991019a99919999901110104a99911109a999410aa1d177777777777777dd0eeeeeeeeeeeeeeeeeeeeeee
eeeeeeee0dd77777777777711d1aaaa019a99999999941019a99914999900009400a99990097a99910aaa1d11777777777777dd0eeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee0dd777777777771d1aaa1a019a99999999410019a9991099aa949aa910a9999aa7a9999101aaa1d177777777777dd0eeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeee01d77777777771d1a0111019a99911111100019a999104999a77a99104a9999999999410110a1d17777777777d10eeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee1dd7777777771d1aa101019a99910000000019a9991019999999994109a99999999910101aa1d1777777777dd1eeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee01dd77777771d1aa0a0019a99910000000019a999101149999999910049999999410a0a0aa1d17777777dd10eeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee11eeee0ddd777771d1aaaaa0111111100000000111111100111049941000001499941001aaaaaa1d177777ddd0eeee11eeeeeeeeeeeeeeeeeeeeeeee
eeeeeeee1dd000001ddd7771d1aaaaa00000000000000000000000000010000000000000000001d1aaaaaa1d1777ddd100000dd1eeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee0ddddd777777771d1aaaaaa1d10000000000000000000000000000000000000000001d1aaaaaa1d177777777ddddd0eeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeee0dd77777777771d1aaaaaa1d10000000000000000000000000000000000000000001d1aaaaaa1d17777777777dd0eeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeee0dd7777777771d1aaaaaa122288888888888888888888888888888888888888882221aaaaaa1d1777777777dd0eeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee0dd7777777722888888888888888888888888888888888888888888888888888888888888882277777777dd0eeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeee01dd777888888888888888888888888888888888888888888888888888888888888888888888888777dd10eeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee1d88888888888800011100088888000000188800000001800000000000008888000000088888888dd1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee8288888888880004999411088100499941018011111111011111111111108011111111008888882eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee02288888888804a7a99999908104a7aaaa940100777aa91197aaa1977aa100104aaa9999188888828eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee228888888814aa9999999001097a99999aa9000799999019a99919a999111097a999999188888828eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee228888888119a9999999911047a999999999400799999919a99919a9991109799999990088888828eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee20888888811a9999011111109a9999999999910799999909a99919a9991097999999991888888828eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee208877777019999aa9401110a99999119999910799999999a99919a99910a9999911940777778828eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee207777777719999999999004a99991110999940a99999999a99919a99914a9999111117777777788eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee407777777701999999999909a99911110a99990a99999999999919a99919a9991111117777777708eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee007777777771149999999904a99911109a99940a9999a999999919a9991999990111010777777709eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee00777777777011100a999910a99990097a99910a99999a99999919a9991499990000940777777709eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee40777777777049a7a9999910a9999aa7a999910a99994799999919a9991099aa949aa91777777709eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeee4077777778009999999999104a9999999999410a999909a9999919a999104999a77a991077777709eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeee840778888800499999999911109a999999999100a999914a9999919a99910199999999941888877098eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeee8822408888888001999999941008004999999941000a99991099999919a9991011499999999188888809228eeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeee888822242888888880001111110088880014999410080111111001111111111111081110499410088888809228888eeeeeeeeeeeeeeeeeeeeeeeeee
eeeeee888888822222888888888800000088888888800000008880000000080000000000000088810000008888888828228888888eeeeeeeeeeeeeeeeeeeeeee
ee88888888888222228888888888888888888888888888888888888888888888888888888888888888888888888888282288888888888eeeeeeeeeeeeeeeeeee
e8888888888882948288888888888888888824444444444444444444444444444444444444288888888888888888822492888888888888eeeeeeeeeeeeeeeeee
ee888888888779948288888888882eee01dd1449494999999999999999999999999994949441dd10eee28888888882249977788888888eeeeeeeeeeeeeeeeeee
eee88888777779948288828eeeeeeeeee01dd11a9a9a9a9a9a9a9a9aa9a9a9a9a9a9a9a9a11dd10eeeeeeeeee2088224997777778888eeeeeeeeeeeeeeeeeeee
eeee8777777779944800028eeeeeeeeeee011d11aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa11d110eeeeeeeeeee200002499777777777eeeeeeeeeeeeeeeeeeeee
eeeee877777779944000028eeeeeeeeeeee001dd1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1dd100eeeeeeeeeeee20000849977777777eeeeeeeeeeeeeeeeeeeeee
eeeeee77777779944080028eeeeeeeeeeeeee011d111aaaaaaaaaaaaaaaaaaaaaaaa111d110eeeeeeeeeeeeee20088449977777778eeeeeeeeeeeeeeeeeeeeee
eeeee877777779942000028eeeeeeeeeeeeeee001ddd111aaaaaaaaaaaaaaaaaa111ddd100eeeeeeeeeeeeeee20000249977777777eeeeeeeeeeeeeeeeeeeeee
eeeee777777779222000008eeeeeeeeeeeeeeeee0111ddd1111aaaaaaaaaa1111ddd1110eeeeeeeeeeeeeeeee000002222777777778eeeeeeeeeeeeeeeeeeeee
eeee877777788222200000eeeeeeeeeeeeeeeeeee00011dddd111111111111dddd11000eeeeeeeeeeeeeeeeee800002222888777777eeeeeeeeeeeeeeeeeeeee
eeee77788888822220008eeeeeeeeeeeeeeeeeeeeeee001111dddddddddddd111100eeeeeeeeeeeeeeeeeeeeee800022228888887778eeeeeeeeeeeeeeeeeeee
eee8888888888222208eeeeeeeeeeeeeeeeeeeeeeeeeee00001111111111110000eeeeeeeeeeeeeeeeeeeeeeeeee8022228888888888eeeeeeeeeeeeeeeeeeee
eee88888888882228eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee822288888888888eeeeeeeeeeeeeeeeeee
ee8888888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888888eeeeeeeeeeeeeeeeeee
ee8888888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888eeeeeeeeeeeeeeeeee
e8888888eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888eeeeeeeeeeeeeeeeee
e88eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888eeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
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
__sfx__
010100203005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050
010400093035030360303703235032360323703435034360343703c30000300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000430350303603037030370323003230034300343003c3000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010800013c35000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000023150000002314023145241400000024140241452614026145000000000026140000002314023140
010c00002314023145231402314524140000002614026140261450000026140000002614026140261450000024140241450000000000241402414500000000002414024145231402314524140000002114021140
010c00002114021140211402114021140211402114021140211402114021140211450000000000000000000023140000002314023145241400000024140241452614026145000000000026140000002314023140
010c00002314023145231402314524140000002614026140261450000026140000002614026140261402614529140291450000000000291402914500000000002914029145281402814529140000002b1402b140
010c00002b1402b1402b1402b1402b1402b1402b1402b1402b1402b1402b1402b1402b1402b1402b1402b14500000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000037130351303213035130371303513032130351303713035130321303513037130351303213035130
010c00003713035130321303513037130351303213035130371303513032130351303713035130321303513039130371303413037130391303713034130371303913037130341303713039130371303413037130
010c000032130301302d1303013032130301302d1303013032130301302d1303013032130301302d1303013037130351303213035130371303513032130351303713035130321303513037130351303213035130
010c00003713035130321303513037130351303213035130371303513032130351303713035130321303513037120351203212035120371103511032110351150000000000000000000000000000000000000000
010c0000000000e1450e145000000e1450e105000000e1450e145000000e145000000e1450e1050e1450e10513145131451314500000131450000013145131450000013145131450000013145000001314500000
010c00000e1450e1450e145000000e145000000e1450e145000000e1450e145000000e14500000101450000011145111451114500000111450000011145111450000011145111450000011145000001114500000
010c00000e1450e1450e145000000e145000000e1450e145000000e1450e145000000e145000000e1450000013145131451314500000131450000013145131450000013145131450000013145000001314500000
010c00000e1450e1450e145000000e145000000e1450e145000000e1450e145000000e14500000101450000011145111451114500000111450000011145111450000011145111450000011145000001514500000
010c00001314513145131450000013145000001314513145000001314513145000001314013130131201312500000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000000002135021350000002135021050000002135021350000002135000000213502135021350213507135071350713500000071350000007135071350000007135071350000007135000000713500000
010c00000213502135021350000002135000000213502135000000213502135000000213500000041350000005135051350513500000051350000005135051350000005135051350000505135000000513500000
010c00000213502135021350000002135000000213502135000000213502135000000213500000021350000007135071350713500000071350000007135071350000007135071350000007135000000713500000
010c00000213502135021350000002135000000213502135000000213502135000000213500000041350000005135051350513500000051350000005135051350000005135051350000005135000000913500000
010c00000713507135071350000007135000000713507135000000713507135000000713007120071200711500000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010800003c3743e3743f3743b3643c3643e364393543b3543c35437344393443b34435344373443934434334353343733435334373343933437324393243b324393243b3243c3243b3143c3143e3143c3143e314
010800003c3243e3243f3243b3343c3343e334393343b3343c33437344393443b34435344373443934434334353343733435334373343933437324393243b324393243b3243c3243b3143c3143e3143c3143e314
010800133fa003ba003ca003ea0039a003ba003ca0037a0039a003ba0035a0037a0039a0034a0035a0037a0035a0037a0039a0037a0039a003ba0039a003ba003ca003ba003ca003ea0000a0000a000000000000
010400002d85000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110300001351013510145101552016520185201b5301e530235312a54100501005010050100501005010050100501005010050100501005010050100501005010050100501005010050100000000000000000000
0108001e3c3003e3003f3003b3003c3003e300393003b3003c30037300393003b30035300373003930034300353003730035300373003930037300393003b300393003b3003c3003b3003c3003e3000030000300
__music__
00 080d1116
00 090e1217
00 0a0f1318
00 0b0e1419
04 0c10151a
00 41424344
00 41424344
00 41424344
00 30424344
03 31424344

