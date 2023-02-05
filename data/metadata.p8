pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- pico sonic
-- by leyn
-- (title and author above will be overwritten by add_metadata.py, also adding version, so don't mind them too much)

-- Usage:
-- 1. Capture a good label with F2 while running the game and export it with PICO-8 0.2.4c+ with `export -l metadata_label.png`
--    or alternatively capture a screenshot with F1 at scale 1.
-- 2. You can then edit it further (e.g. to remove the version number) with a pixel art editor and save it in data/metadata_label.png
--    for versioning
-- 3. Copy it in pico-8 carts folder
-- 4. Open this file with pico8 -run to run the code below on launch and import it
-- Note that Sublime Text command: "Game: edit metadata" will automatically do steps 3 and 4

-- Import latest label (requires PICO-8 0.2.4c+)
import("-l metadata_label.png")

__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111111000111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111010070111110777010111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110707070011111007007011
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110707077701110777077701
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110777070701010700107011
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111070077700700777010111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101100011011000111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111cccc11111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111cccccccccc111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111cccccccccccccc11111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111d11cccccc1111cccc1111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111d7711cccccc11cccccc111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111d77d1cccccc11cc441cc1111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111d777d11ccccc11cc44ff1cc1177d11111111111111111111111111111111111111111111111111
1111111111d11111111111111111111111111111111111111d7d111cccccc1cc44ffff1c1111d7d11111111111111111111111111111111111111d1111111111
1111111111d7dd111111111111111111111111111111111d711111ccccccccc4ffffff1c11441117d111111111111111111111111111111111dd7d1111111111
1111111110dd777dd11111111111111111111111111111111111cccccccccccccfffff1c11a99411d751111111111111111111111111111dd777dd0111111111
11111111111d777777dd1111111111111111111111111ccccc1ccccccccccccccccfff1c1aaaaa441575111111111111111111111111dd777777d11111111111
111111111111d77777777dd11111111111111111111111ccc1cccccccccc111ccccccfcc111111a95677511111111111111111111dd77777777d111111111111
111111111110dd77777777777dd111111111111111dd111c1cccccccccc1ccc1cccccccc1ccccc1166775d111111111111111dd77777777777dd011111111111
1111111111110dd77777777777777dd1111111111d1111111ccccccccccccccccccc7cc1ccccccc5667511d1111111111dd77777777777777dd0111111111111
11111111111111dd77777777777777777dd11111d114a111ccccccccccccccccccc777ccccccccc56775411d11111dd77777777777777777dd11111111111111
111111111111110dd7777777777777777777771dd14aaa11ccccccccccc1111ccccc7ccccccccc56675aa41dd1777777777777777777777dd011111111111111
1111111111111111dd7777777777777777777d1d14aaaaa11ccccccccc177771cccccccccccccc5667c1aa41d1d7777777777777777777dd1111111111111111
111111111111111101d77777777777777777d1d14aaaa11cc1ccccccc1777777ccccccccccccc55675c1aaa41d1d77777777777777777d101111111111111111
1111111111111111110d77777777777777771d11aaaaa1ccccccccccc17775771cccccccccc5666575cc1aaa11d17777777777777777d0111111111111111111
11111111111111111111dd7777777777777d1d19aaaaa1cccccccccc177770571cccccccc566777765cc1aaa91d1d7777777777777dd11111111111111111111
1111111111dd1011111110dd777777777771d14a1aaaa1ccc1cccccc177770071ccccccc5666655777111aa1a41d177777777777dd0111111101dd1111111111
11111111111d77d10111111ddd777777771dd101110aa11c171cc1c1777770071ccccccc56557777775aa011101dd177777777ddd11111101d77d11111111111
11111111110dd7777d1011101ddd7777771d19a101aa1d1c1771c1c177777007ccccccc5555667777751aa101a91d1777777ddd1011101d7777dd01111111111
111111111111d77777771100000dd7777d1d1aa0a0aa1d1c1777001777777007cccfff56655655667751aa0a0aa1d1d7777dd00000117777777d111111111111
111111111110dd77777777777777777771d19aaaaaa1d101c777007777777707cff7775676556677775d1aaaaaa91d17777777777777777777dd011111111111
1111111111110dd7777777777777777771d1aaaaaa1dd101c17750777777777cfffffff567566677771dd1aaaaaa1d1777777777777777777dd0111111111111
11111111111111d777777777777777771d11aaaaaa1d1001cc777577777777ffff00fffc565665567601d1aaaaaa11d177777777777777777d11111111111111
111111111111111d77777777777777771d1aaaaaaa1d10001cc7774fff77fffffff0fff5655666567501d1aaaaaaa1d17777777777777777d111111111111111
111111111111110dd7777777777777771d1aaaaaa1d100000006650fffffffffff0fffc56665656770001d1aaaaaa1d1777777777777777dd011111111111111
1111111111111110dd777777777777771d1aaaaaa1d1000000000000ffffffff00ffff115666567750001d1aaaaaa1d177777777777777dd0111111111111111
11111111111111110dd77777777777711d1aaaaaa1d100000000000fffffffffffff41115667777100001d1aaaaaa1d11777777777777dd01111111111111111
111111111111111110dd777777777771d1aaa1aa1dd100000000044fffffffffff4411cc5667775100001dd1aa1aaa1d177777777777dd011111111111111111
11111111111111111101d77777777771d1a011101d1000000000040444fffff4441111c5655675c1000001d101110a1d17777777777d10111111111111111111
11111111111111111111dd7777777771d1aa101a1d10000000000440004444400f41111566667510000001d1a101aa1d1777777777dd11111111111111111111
1111111111111111111101dd77777771d1aa0a0a1d10000000004f414444444ffff1111156677500000001d1a0a0aa1d17777777dd1011111111111111111111
11111111111111111111110ddd777771d1aaaaaa1d1000000000ff4444fffffffff11111f5555000000001d1aaaaaa1d177777ddd01111111111111111111111
11111111111111111dd000001ddd7771d1aaaaaa1d1000000004ff44ffffffff7ff11111fff40000000001d1aaaaaa1d1777ddd100000dd11111111111111111
111111111111111110ddddd777777771d1aaaaaa1d100000004fff14ffffffff7ff14114ff400000000001d1aaaaaa1d177777777ddddd011111111111111111
1111111111111111110dd77777777771d1aaaaaa1d10000004ffff14fffffffffff4414fff000000000001d1aaaaaa1d17777777777dd0111111111111111111
11111111111111111110dd7777777771d1aaaaaa122288888888888888888888888888888888888888882221aaaaaa1d1777777777dd01111111111111111111
111111111111111111110dd7777777722888888888888888888888888888888888888888888888888888888888888882277777777dd011111111111111111111
11111111111111111111101dd777888888888800000000000008800000000888800000008888800000018888888888888888777dd10111111111111111111111
111111111111111111111111d88888888888880111111111111080111111108011111111008100499941018888888888888888dd111111111111111111111111
11111111111111111111111182888888888888019777aaaa9941001977aa100104aaa99991104a7aaaa940188888888888888821111111111111111111111111
11111111111111111111111022888888888888019799999999941019a999111097a9999991097a99999aa9008888888888888828111111111111111111111111
11111111111111111111111122888888888888019799999999991019a9991109799999990047a999999999408888888888888828111111111111111111111111
11111111111111111111111122888888888888019799911199994119a999109799999999109a9999999999910888888888888828111111111111111111111111
1111111111111111111111112088888887777701979991110a999119a99910a99999119400a99999119999910777777888888828111111111111111111111111
11111111111111111111111120887777777777019a9991110a994119a99914a99991111104a99991110999941077777777778828111111111111111111111111
11111111111111111111111120777777777777019a9990007a991019a99919a99911111109a99911110a99991077777777777788111111111111111111111111
11111111111111111111111140777777777777019a999aa7a9991019a99919999901110104a99911109a99941077777777777708111111111111111111111111
11111111111111111111111100777777777777019a99999999941019a99914999900009400a99990097a99910777777777777709111111111111111111111111
11111111111111111111111100777777777777019a99999999410019a9991099aa949aa910a9999aa7a999910777777777777709111111111111111111111111
11111111111111111111111140777777777777019a99911111108019a999104999a77a99104a9999999999410777777777777709111111111111111111111111
11111111111111111111111140777777788888019a99910000088019a9991019999999994109a999999999108888888777777709111111111111111111111111
11111111111111111111111840778888888888019a99910888888019a99910114999999991004999999941088888888888887709811111111111111111111111
11111111111111111111882240888888888888011111110888888011111110811104994100800149994100888888888888888809228111111111111111111111
11111111111111111888822242888888888888000000000888888000000000888100000088888000000088888888888888888809228888111111111111111111
11111111111111888888822222888888888888888888888888888888888888888888888888888888888888888888888888888828228888888111111111111111
11111111118888888888822222888888888888888888888888888888888888888888888888888888888888888888888888888828228888888888811111111111
11111111188888888888829482888888888888888888244444444444444444444444444444444444442888888888888888888224928888888888881111111111
111111111188888888877994828888888888211101dd1449494999999999999999999999999994949441dd101112888888888224997778888888811111111111
1111111111188888777779948288828111111111101dd11a9a9a9a9a9a9a9a9aa9a9a9a9a9a9a9a9a11dd1011111111112088224997777778888111111111111
111111111111877777777994480002811111000111000d11aa0000001aaa00000001a0000000000000d110000000011112000024997777777771111111111111
1111111111111877777779944000028111100049994110dd10049994101a01111111101111111111110001111111100112000084997777777711111111111111
111111111111117777777994408002811104a7a99999901104a7aaaa940100777aa91197aaa1977aa100104aaa99991112008844997777777811111111111111
11111111111118777777799420000281114aa9999999001097a99999aa9000799999019a99919a999111097a9999991112000024997777777711111111111111
11111111111117777777792220000081119a9999999911047a999999999400799999919a99919a99911097999999900110000022227777777781111111111111
1111111111118777777882222000001111a9999011111109a9999999999910799999909a99919a99910979999999911118000022228887777771111111111111
11111111111177788888822220008111019999aa9401110a99999119999910799999999a99919a99910a99999119401111800022228888887778111111111111
11111111111888888888822220811111119999999999004a99991110999940a99999999a99919a99914a99991111111111118022228888888888111111111111
11111111111888888888822281111111101999999999909a99911110a99990a99999999999919a99919a99911111111111111182228888888888811111111111
11111111118888888888888111111111111149999999904a99911109a99940a9999a999999919a99919999901110101111111111188888888888811111111111
1111111111888888888811111111111111011100a999910a99990097a99910a99999a99999919a99914999900009401111111111111188888888881111111111
1111111118888888111111111111111111049a7a9999910a9999aa7a999910a99994799999919a9991099aa949aa911111111111111111118888881111111111
111111111881111111111111111111111009999999999104a9999999999410a999909a9999919a999104999a77a9910111111111111111111111888111111111
1111111111111111111111111111111d00499999999911109a999999999100a999914a9999919a99910199999999941111111111111111111111111111111111
111111111111111111111111111111d6001999999941007004999999941000a99991099999919a99910114999999991111111111111111111111111111111111
111111111111111111111111111111d7700011111100777700149994100101111110011111111111110111104994100111111111111111111111111111111111
11111111111111111111111111111d67777000000777777766000000011100000000100000000000000111100000011111111111111111111111111111111111
11111111111111111111111111111d6777777777777777777776d111111111111111111111111224911111111111111111111111111111111111111111111111
11111111dd6611111111111111111d67777777777777777777776d11111111111111111111111224911111111111d66d11111111111111111111111111111111
1111111d67776dddd11111111111d667772477777777777777777d1111111111111111111111122449111111ddd67776d1241111111111111111111111111111
11111111777776776d11111dd1dd6667772477777777777777777d11111111111111111111111224491111166776777761241111111111111111111111111111
1111111d7777777776d111d666677777772277777777777777777d11111111111111111111112224249749167777777766221111111111111111111111111111
111111666777777777d6666666777777772277777777777777777661111111111111111111121224224449677777777766221111111111111111111111111111
1111d66777777777776777766677777777224977777777777777776d11111111111119911112212222442467777777777622491111111ddddddd11111111ddd6
111166777777777777777777666777777722497777777777777777661111111111111491112212222244249649777777662249111111d666666dd11111166776
11166777777777777777777766677777272229729777777777777776d666d1111111129494212122122424492967777626222912966666776666666d11677777
11166777777777777777777777777677242224229777777777777776666666dd66d1424494b3bb121b2224442496776924222422966667777766776766777777
11d66677777777777777777777777677222222229477777777777777666666d6666442bbb1333bb1b3b2b2442249696422222222947777767777777777777777
1d677777777777777777777777777774222b2222224774677777777776777776643422b3b331333bb3bbbbb222444964222b2222224977776777776676777777
d677777777777777777777777777244421313b22322424467777777667777744bb3b3333b33313333bb3333b1324444223113b22322429777777777667777777
66777777777777777777777777772333131313bb333332244966677767777744333333341221313331333b1113b32224111313b1333332244977777767777777
7777777777777777777777777442233331111113311131322224ddddddddd43b31122424242211311111331b3333113331111113311131322224777766777777
ddddddddddddddddddddddddddddddd11dd11dd13bdddd11dddddd67dddddddd1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddd6d676d6dddddddddddddddddddddddddddd76dddd67dd1ddddd67ddddddddd6676dddddddddddddddddd676d6ddddddddd666ddddddd66dd
1ddddddd666666dddddddddddd6d6776d6ddddddddddddddddddddddddddddddddddddddd1dddddddddddddddddd666dddddddddddddddd66666ddd1ddd66666
11dd1ddddd666ddddddddddddddddddddddddddddd666ddddddd1ddd11dd111111111dd1111ddddddd1dddd6dd666666d6ddddddddddd666666dd1111dddd666
11111111dddddddddddd11111111dddddd676ddd6666ddddddd1111111111111111111111111dd67dd111d666666666666ddd1111111dddddddd11111111dddd
1111111111ddd111dd11111111111dddddddddd6666dd1ddd1111111111111111111111111111dddd1111dd66666767766ddd1111111111111111111111111dd
11111111111111111111111111111111dddddd66dddd11111111dd11111111111dd1111111111dddd11111dd666666666dd111111dd111111111111111111111
1111111111111111111111111dd1111111ddddddddd11111111111111111111111111111dd1111dd1111111ddddd6666dd111111111111ddd111111111111111
11111ddd11111111111111111111111111111111111111111111111111111111111111111111111111111111111ddddd11111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111ddd1111111111111111111111111111111111111111111111111111111dddd11111111
11111111111111111ddd11111111111111111111111dd11111111111111111111111111111111dd111111ddd111111111111dd11111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
