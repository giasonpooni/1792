"""Original courtyard bay and fitted childhood costume. Run in Blender 4.x.

blender --background --factory-startup --python tools/art/build_courtyard.py -- --output /new/directory
The .blend sources are retained with exports. No network or third-party assets.
These are authored visual interpretations for the compressed prototype, not surveys.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
from mathutils import Vector


def point(p):
    """Authored East/Up/South local axes -> Blender X/Y/Z."""
    return Vector((p[0], -p[2], p[1]))


def material(name, color, roughness=0.85, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    # Input palette is display sRGB, Blender/glTF base factors are linear.
    rgb = [int(color[i:i+2], 16)/255 for i in (0, 2, 4)]
    linear = [c/12.92 if c <= .04045 else ((c+.055)/1.055)**2.4 for c in rgb]
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*linear, 1)
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metallic
    m.diffuse_color = (*linear, 1)
    return m


def apply_mat(obj, mat):
    obj.data.materials.append(mat)
    return obj


def bevel(obj, amount=.018, segments=3):
    if amount:
        m = obj.modifiers.new('Rounded construction edges', 'BEVEL')
        m.width = amount; m.segments = segments
        m = obj.modifiers.new('Weighted surface normals', 'WEIGHTED_NORMAL')
        m.keep_sharp = True
    return obj


def box(name, at, size, mat, edge=.018):
    bpy.ops.mesh.primitive_cube_add(size=1, location=point(at))
    obj = bpy.context.object; obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    apply_mat(obj, mat); bevel(obj, edge)
    return obj


def mesh(name, vertices, faces, mat, smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata([point(v) for v in vertices], [], faces); data.update()
    obj = bpy.data.objects.new(name, data); bpy.context.collection.objects.link(obj)
    apply_mat(obj, mat)
    for p in data.polygons: p.use_smooth = smooth
    return obj


def rings(name, levels, mat, segments=40, folds=0.0):
    # Closed loft with controlled ellipsoidal sections: y, rx, rz, cx, cz.
    v = []
    for row, (y, rx, rz, cx, cz) in enumerate(levels):
        for i in range(segments):
            a = i*math.tau/segments
            f = 1 + folds*math.cos(a*12 + row*.08)
            v.append((cx+rx*math.cos(a)*f, y, cz+rz*math.sin(a)*f))
    faces = []
    for r in range(len(levels)-1):
        for i in range(segments):
            j=(i+1)%segments; a=r*segments
            faces.append((a+i,a+j,a+segments+j,a+segments+i))
    faces.extend([tuple(reversed(range(segments))), tuple((len(levels)-1)*segments+i for i in range(segments))])
    obj=mesh(name,v,faces,mat,True)
    # Consistent normals for lofts despite the axis conversion.
    bpy.context.view_layer.objects.active=obj;obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT');obj.select_set(False)
    return obj


def tube(name, a, b, radius, mat):
    start,end=point(a),point(b); d=end-start
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=d.length, location=(start+end)/2)
    obj=bpy.context.object;obj.name=name;obj.rotation_euler=d.to_track_quat('Z','Y').to_euler()
    apply_mat(obj,mat);bevel(obj,.007,2)
    return obj


def new_scene():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.materials): bpy.data.materials.remove(block)


def export(output, name):
    # Apply modifiers and unwrap locally; no implicit Godot collision suffixes.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in list(bpy.context.scene.objects):
        if obj.type != 'MESH': continue
        bpy.context.view_layer.objects.active=obj;obj.select_set(True)
        for modifier in list(obj.modifiers):
            if modifier.type != 'ARMATURE': bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=1.1519, island_margin=.01)
        bpy.ops.object.mode_set(mode='OBJECT');obj.select_set(False)
    bpy.ops.wm.save_as_mainfile(filepath=str(output/(name+'.blend')))
    # Preserve editable components in .blend; batch export by material for draw cost.
    bpy.ops.object.select_all(action='DESELECT')
    parts=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in parts:o.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
    bpy.context.object.name='CourtyardBay' if name=='courtyard_bay' else 'ChildhoodCostume'
    bpy.ops.export_scene.gltf(filepath=str(output/(name+'.glb')),export_format='GLB',
        export_yup=True,export_texcoords=True,export_normals=True,export_materials='EXPORT',
        export_animations=False,export_extras=True)
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    tris=0
    for o in meshes: o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
    return {'file':name+'.glb','sha256':hashlib.sha256((output/(name+'.glb')).read_bytes()).hexdigest(),
            'mesh_objects':len(meshes),'triangles':tris,'blend_sha256':hashlib.sha256((output/(name+'.blend')).read_bytes()).hexdigest()}


def bay():
    new_scene()
    plaster=material('lime_plaster','baae96');stone=material('worn_plinth','9c8870')
    wood=material('old_timber','68513e');paint=material('painted_shutter','526f67')
    iron=material('forged_iron','41413d',.62,.65);brick=material('brick','a8795b');dark=material('recess','302c25')
    # One 4.25 m bay; faces stay close to the inherited solid back wall.
    for x in (-2.125,2.125):
        rings('Pier',[(.1,.19,.19,x,0),(.28,.21,.21,x,0),(.36,.15,.15,x,0),(1.96,.145,.145,x,0),(2.08,.23,.20,x,0),(2.17,.21,.20,x,0)],plaster,8)
        box('Square plinth',(x,.11,0),(.46,.22,.46),stone,.025)
        box('Capital',(x,2.16,0),(.54,.14,.46),plaster)
    # Actual continuous arch ring and separate flush voussoir scoring.
    for ring in range(2):
        verts=[]; faces=[]; steps=48
        inner_x=1.89+ring*.15; inner_y=.89+ring*.13
        for k in range(steps+1):
            a=k*math.pi/steps
            for radius,depth in [(0,-.16),(1,-.16),(0,.16),(1,.16)]:
                verts.append(((inner_x+.14*radius)*math.cos(a),2.1+(inner_y+.12*radius)*math.sin(a),depth))
        for k in range(steps):
            i=k*4;j=i+4
            faces.extend([(i,j,j+1,i+1),(i+2,i+3,j+3,j+2),(i,i+2,j+2,j),(i+1,j+1,j+3,i+3)])
        obj=mesh('Arch moulding',verts,faces,plaster);bevel(obj,.008,2)
    box('Cornice',(0,3.31,.10),(4.25,.18,.62),plaster)
    box('Cornice lip',(0,3.42,-.07),(4.25,.065,.76),stone,.008)
    box('Roof beam',(0,3.58,.34),(4.25,.22,2.30),wood)
    for i in range(12):
        box('Exposed rafter',(-1.95+i*.354,3.38,.2),(.105,.13,2.47),wood,.012)
    # Closed double leaf door: explicitly not an enterable interior.
    box('Door recess',(0,1.28,.365),(1.49,2.48,.06),dark,.003)
    for x in (-.82,.82):
        box('Carved door jamb',(x,1.30,.26),(.15,2.58,.16),wood,.01)
        for y in (.25,.72,1.8,2.39): box('Jamb collar',(x,y,.20),(.19,.045,.045),stone,.005)
    box('Lintel',(0,2.59,.25),(1.82,.17,.19),wood)
    box('Threshold',(0,.10,.20),(1.88,.12,.40),stone)
    for side in (-1,1):
        cx=side*.365
        for i in range(5):box('Shutter plank',(cx+(i-2)*.136,1.29,.305),(.13,2.34,.08),paint,.007)
        for y in (.29,1.18,2.24):box('Door cross rail',(cx,y,.23),(.69,.065,.07),wood,.009)
        for y in (.34,2.18):
            box('Iron strap',(cx,y,.182),(.56,.033,.018),iron,.005)
            for dx in (-.23,.23):
                bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.022,location=point((cx+dx,y,.165)))
                apply_mat(bpy.context.object,iron)
    # Small recessed lattice panels, framed as ordinary domestic joinery.
    for side in (-1,1):
        cx=side*1.40
        box('Panel recess',(cx,1.38,.36),(.60,.92,.04),dark,.005)
        for dx in (-.33,.33):box('Panel frame',(cx+dx,1.38,.28),(.055,1.03,.10),wood,.007)
        for y in (.865,1.895):box('Panel sill',(cx,y,.26),(.72,.065,.13),wood)
        for i in range(5):box('Screen upright',(cx-.24+i*.12,1.38,.29),(.019,.88,.028),wood,.003)
        for i in range(7):box('Screen rail',(cx,.98+i*.13,.276),(.54,.019,.028),wood,.003)
    for row in range(2):
        for col in range(12):
            x=-1.94+col*.351+(row%2)*.12
            if abs(x)<1:continue
            box('Skirting brick',(x,.20+row*.115,.34),(.32,.105,.12),brick,.008)


def child():
    new_scene()
    cloth=material('child_cotton','b3aa8d');trousers=material('child_trousers','667271')
    sash=material('child_sash','61766e');skin=material('child_skin','b18a69',.80)
    hair=material('child_hair','382a20');eyes=material('child_eyes','292523',.4)
    shoes=material('child_leather','514032',.72)
    # Same rest-joint coordinates as the retained locomotion skeleton.
    parents={'pelvis':'','spine':'pelvis','head':'spine'}
    rests={'pelvis':(0,.8,0),'spine':(0,.95,0),'head':(0,1.4,0)}
    for sign,s in [(-1,'L'),(1,'R')]:
        for n,par,p in [('upper_leg','pelvis',(sign*.13,.8,0)),('lower_leg','upper_leg'+s,(sign*.13,.44,0)),('upper_arm','spine',(sign*.25,1.25,0)),('forearm','upper_arm'+s,(sign*.25,.97,0))]:
            parents[n+s]=par;rests[n+s]=p
    armdata=bpy.data.armatures.new('Childhood garment rig');rig=bpy.data.objects.new('ChildhoodRig',armdata)
    bpy.context.collection.objects.link(rig);bpy.context.view_layer.objects.active=rig;rig.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for n,p in rests.items():
        b=armdata.edit_bones.new(n);b.head=point(p);b.tail=point((p[0],p[1]+.12,p[2]))
        if parents[n]:b.parent=armdata.edit_bones[parents[n]]
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    def bind(obj,bone):
        g=obj.vertex_groups.new(name=bone);g.add(list(range(len(obj.data.vertices))),1.0,'REPLACE')
        mod=obj.modifiers.new('Existing motor pose projection','ARMATURE');mod.object=rig
    obj=rings('Continuous cotton tunic',[(.56,.245,.145,0,0),(.65,.244,.15,0,0),(.83,.215,.13,0,0),(.96,.20,.13,0,0),(1.14,.235,.148,0,0),(1.27,.24,.145,0,0),(1.32,.135,.105,0,0)],cloth,48,.025);bind(obj,'spine')
    bind(rings('Woven waist sash',[(.82,.225,.145,0,0),(.855,.229,.149,0,0),(.92,.219,.144,0,0)],sash,48,.014),'pelvis')
    for sign,s in [(-1,'L'),(1,'R')]:
        x=sign*.13
        bind(rings('Trouser upper '+s,[(.40,.104,.115,x,0),(.55,.12,.125,x,0),(.75,.125,.127,x,0),(.81,.12,.12,x,0)],trousers,32,.06),'upper_leg'+s)
        bind(rings('Trouser lower '+s,[(.12,.073,.086,x,0),(.26,.082,.089,x,0),(.44,.106,.111,x,0),(.49,.109,.115,x,0)],trousers,32,.08),'lower_leg'+s)
        bind(rings('Leather shoe '+s,[(.015,.087,.16,x,-.055),(.05,.099,.167,x,-.057),(.115,.077,.136,x,-.024),(.16,.069,.078,x,.008)],shoes,32),'lower_leg'+s)
        x=sign*.25
        bind(rings('Cotton sleeve '+s,[(.92,.075,.083,x,0),(1.00,.088,.094,x,0),(1.18,.10,.105,x,0),(1.27,.105,.107,x,0)],cloth,32,.026),'upper_arm'+s)
        bind(rings('Forearm '+s,[(.71,.042,.046,x,0),(.80,.048,.05,x,0),(.92,.064,.068,x,0),(.99,.067,.07,x,0)],skin,32),'forearm'+s)
        bind(rings('Hand '+s,[(.615,.036,.049,x,-.006),(.66,.044,.052,x,0),(.718,.039,.044,x,0)],skin,24),'forearm'+s)
        bind(tube('Thumb '+s,(x-sign*.045,.70,-.008),(x-sign*.052,.64,-.03),.017,skin),'forearm'+s)
    bind(rings('Neck',[(1.27,.066,.066,0,0),(1.43,.068,.067,0,0)],skin,32),'head')
    bind(rings('Face',[(1.405,.061,.069,0,-.009),(1.44,.103,.096,0,-.008),(1.52,.127,.111,0,0),(1.60,.124,.108,0,.01),(1.65,.092,.09,0,.012)],skin,48),'head')
    bind(mesh('Nose',[(-.024,1.535,-.102),(.024,1.535,-.102),(0,1.485,-.139),(-.024,1.482,-.103),(.024,1.482,-.103)],[(0,1,2),(0,2,3),(1,4,2),(3,2,4)],skin,True),'head')
    for x in (-.049,.049):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=1,location=point((x,1.544,-.099)))
        o=bpy.context.object;o.scale=(.017,.010,.01);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);apply_mat(o,eyes);bind(o,'head')
    for i in range(6):
        y=1.616+i*.018;rx=.147-math.pow((i-2.5)/5,2)*.04
        bind(rings('Headwrap fold',[(y-.013,rx,.128,0,.009),(y,rx+.007,.135,0,.009),(y+.015,rx,.127,0,.009)],cloth,48,.015),'head')
    bind(rings('Headwrap crown',[(1.70,.116,.10,0,.01),(1.74,.071,.065,0,.01),(1.752,.015,.016,0,.01)],cloth,40),'head')


def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True)
    a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);a.output.mkdir(parents=False,exist_ok=False)
    records=[]
    bay();records.append(export(a.output,'courtyard_bay'))
    child();records.append(export(a.output,'childhood_costume'))
    report={'schema':'1792.blender-courtyard.v1','classification':'original-authoring-study',
        'historically_verified':False,'georeferenced':False,'blender':bpy.app.version_string,
        'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'assets':records}
    (a.output/'build.json').write_text(json.dumps(report,indent=2)+'\n')
    print('COURTYARD_ASSETS: exported two Blender scenes')

if __name__=='__main__':main()
