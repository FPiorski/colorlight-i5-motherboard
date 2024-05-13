#!/bin/bash

set -e
set -x

LAYERCOUNT=4

PCBNAME=""
for i in *.kicad_pro; do
    PCBNAME=$(basename $i .kicad_pro)
done


HASH=$(git rev-parse --short=8 HEAD)
TAG1=$(git tag --points-at HEAD | head -n1)
REV=""
if [[ $TAG1 == "rev-"* ]]; then
    REVFULL=$(echo $TAG1 | sed -e "s/rev-//")
    REV="$(printf '%c' "$REVFULL")"
    echo $REV
fi

sed -i "s/comment 3 \"xxxxxxxx\"/comment 3 \"$HASH\"/" "$PCBNAME.kicad_sch"
sed -i "s/rev \"x\"/rev \"$REV\"/" "$PCBNAME.kicad_sch"
if [ -d "sch/" ]; then
    for i in sch/*.kicad_sch; do
        sed -i "s/comment 3 \"xxxxxxxx\"/comment 3 \"$HASH\"/" "$i"
        sed -i "s/rev \"x\"/rev \"$REV\"/" "$i";
    done
fi
sed -i "s/\"hashhash\"/\"$HASH\"/" "$PCBNAME.kicad_pcb"

OUTDIR="out-$HASH"
if [ -d $OUTDIR ]; then
  echo "Directory out exists."
  exit 1
fi

mkdir $OUTDIR
cd $OUTDIR
kicad-cli sch export pdf --output "$PCBNAME-$HASH.pdf" --theme "KiCad Classic" "../$PCBNAME.kicad_sch"
mkdir gerb-$PCBNAME-$HASH
cd gerb-$PCBNAME-$HASH
if [ "$LAYERCOUNT" == "2" ]; then
    kicad-cli pcb export gerbers --no-x2 --no-netlist --subtract-soldermask --precision 6 --layers "F.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts" "../../$PCBNAME.kicad_pcb"
fi
if [ "$LAYERCOUNT" == "4" ]; then
    kicad-cli pcb export gerbers --no-x2 --no-netlist --subtract-soldermask --precision 6 --layers "F.Cu,In1.Cu,In2.Cu,B.Cu,F.Paste,B.Paste,F.Silkscreen,B.Silkscreen,F.Mask,B.Mask,Edge.Cuts" "../../$PCBNAME.kicad_pcb"
fi
kicad-cli pcb export drill --format "excellon" --drill-origin "absolute" --excellon-zeros-format "decimal" --excellon-units "mm" --excellon-separate-th --generate-map --map-format "gerberx2" --gerber-precision 6 "../../$PCBNAME.kicad_pcb"
cd ..
zip -r "gerb-$PCBNAME-$HASH.zip" "gerb-$PCBNAME-$HASH/"
