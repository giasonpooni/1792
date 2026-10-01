"""Inspect a binary STL without admitting or redistributing it as a game asset."""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import struct
from pathlib import Path


def inspect(path: Path) -> dict:
    size=path.stat().st_size
    if size<84 or size>100_000_084: raise ValueError('Outside binary-STL inspection budget')
    raw=path.read_bytes(); count=struct.unpack_from('<I',raw,80)[0]
    if size!=84+50*count or count==0: raise ValueError('Unsupported, empty or inconsistent binary STL')
    lo=[math.inf]*3; hi=[-math.inf]*3
    for tri in struct.iter_unpack('<12fH',raw[84:]):
        if not all(math.isfinite(v) for v in tri[:12]): raise ValueError('Nonfinite geometry')
        for j in range(3):
            for k in range(3):
                v=tri[3+j*3+k];lo[k]=min(lo[k],v);hi[k]=max(hi[k],v)
    return {'schema':'1792.user-mesh-inspection.v1','filename':path.name,'sha256':hashlib.sha256(raw).hexdigest(),
            'format':'binary STL','bytes':size,'triangles':count,'finite_vertices':True,'bounds_raw_units':[lo,hi],
            'units':'not declared by STL','material_uv_rig':'not represented by standard STL',
            'license_status':'not established','runtime_admission':False,'redistribution':False}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('path',type=Path);parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();report=inspect(args.path)
    with args.output.open('x',encoding='utf-8') as out: json.dump(report,out,indent=2);out.write('\n')
