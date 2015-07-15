#!/bin/bash
# lus = Lapdog Update SPICE
#by FKJN 27/8 2014
kernelpath='/Users/frejon/lapdog/kernels/'
lapdogpath='/Users/frejon/lapdog'
metakernel=$lapdogpath'/metakernel_rosetta.txt'

#sync all elias kernels
rsync -rz frejon@spis.irfu.se:/home/elias/Rosetta/SPICE/kernels/ $kernelpath

#pirate elias metakernel file
scp frejon@spis.irfu.se:/home/elias/Rosetta/MATLAB/metakernel_rosetta.txt $lapdogpath'/'
#scp frejon@spis.irfu.se:/home/elias/Rosetta/SPICE/rosetta_custom_coordinates.tf $lapdogpath'/'


#replace incorrect paths with new paths

sed -i ''  "s@/home/elias/Rosetta/SPICE@$lapdogpath@g" $metakernel
sed -i '' "s@/home/elias@$lapdogpath@g" $metakernel
sed -i '' "s@/share/SPICE/mice@$lapdogpath/mice@g" $metakernel
