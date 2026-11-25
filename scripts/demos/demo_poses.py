#!/usr/bin/env python3
"""Keyframes for Home Workout mannequin demos. Original poses."""
from __future__ import annotations
import math
import numpy as np
from mannequin import standing, side_plank_base

def _d(**kw):
    return {k: np.asarray(v, float) for k, v in kw.items()}

def ex_push_up(wide=0.16, close=False, incline=0.0, decline=0.0, pike=False):
    hand_y = 0.04 + incline
    foot_y = 0.06 + decline
    hy = 0.32 + (0.06 if pike else 0.0) + incline * 0.15
    high = side_plank_base(hip_y=hy)
    for s, e, w in (("ls","le","lw"),("rs","re","rw")):
        x = (-1 if s[0]=="l" else 1) * wide
        if close: x *= 0.35
        high[s] = np.array([x, hy+0.01, 0.36])
        high[e] = np.array([x, hy*0.55 + hand_y*0.2, 0.34])
        high[w] = np.array([x, hand_y, 0.38])
    high["la"][1] = high["ra"][1] = high["lt"][1] = high["rt"][1] = foot_y
    if pike:
        high["pelvis"] = np.array([0.0, hy+0.22, 0.02])
        high["chest"] = np.array([0.0, hy+0.02, 0.28])
        high["head"] = np.array([0.0, hy-0.06, 0.50])
        high["ls"], high["rs"] = np.array([-wide, hy-0.04, 0.32]), np.array([wide, hy-0.04, 0.32])
        high["le"], high["re"] = np.array([-wide, (hy+hand_y)*0.4, 0.30]), np.array([wide, (hy+hand_y)*0.4, 0.30])
        high["lw"], high["rw"] = np.array([-wide, hand_y, 0.32]), np.array([wide, hand_y, 0.32])
    low = {k: v.copy() for k, v in high.items()}
    drop = 0.16 if not pike else 0.10
    for k in ("pelvis","chest","head","ls","rs","lh","rh","lk","rk"):
        low[k] = low[k] + np.array([0, -drop, 0])
    for e, s, w in (("le","ls","lw"),("re","rs","rw")):
        x = high[e][0] * (1.4 if not close else 0.9)
        low[e] = np.array([x, (high[s][1]-drop+hand_y)*0.5, high[w][2]-0.10])
        low[w] = high[w].copy()
    return [high, low]

def ex_squat():
    stand = standing(stance=0.12)
    low = standing(stance=0.16)
    low["pelvis"] = np.array([0.0, 0.52, -0.08])
    low["chest"] = np.array([0.0, 0.76, 0.00])
    low["head"] = np.array([0.0, 1.02, 0.04])
    low["ls"], low["rs"] = np.array([-0.20, 0.78, 0.06]), np.array([0.20, 0.78, 0.06])
    low["le"], low["re"] = np.array([-0.20, 0.70, 0.28]), np.array([0.20, 0.70, 0.28])
    low["lw"], low["rw"] = np.array([-0.18, 0.68, 0.50]), np.array([0.18, 0.68, 0.50])
    low["lh"], low["rh"] = np.array([-0.14, 0.50, -0.04]), np.array([0.14, 0.50, -0.04])
    low["lk"], low["rk"] = np.array([-0.16, 0.28, 0.18]), np.array([0.16, 0.28, 0.18])
    low["la"], low["ra"] = np.array([-0.16, 0.08, 0.02]), np.array([0.16, 0.08, 0.02])
    low["lt"], low["rt"] = np.array([-0.16, 0.04, 0.12]), np.array([0.16, 0.04, 0.12])
    return [stand, low]

def ex_glute_bridge():
    def pose(hip_y):
        pel = np.array([0.0, hip_y, 0.0])
        chest = np.array([0.0, 0.10+hip_y*0.15, -0.28])
        head = np.array([0.0, 0.11, -0.54])
        return dict(pelvis=pel, chest=chest, head=head,
            ls=np.array([-0.18,0.08,-0.26]), rs=np.array([0.18,0.08,-0.26]),
            le=np.array([-0.22,0.06,-0.05]), re=np.array([0.22,0.06,-0.05]),
            lw=np.array([-0.20,0.05,0.14]), rw=np.array([0.20,0.05,0.14]),
            lh=np.array([-0.10,hip_y-0.02,0.04]), rh=np.array([0.10,hip_y-0.02,0.04]),
            lk=np.array([-0.12,0.28,0.22]), rk=np.array([0.12,0.28,0.22]),
            la=np.array([-0.12,0.07,0.12]), ra=np.array([0.12,0.07,0.12]),
            lt=np.array([-0.12,0.04,0.22]), rt=np.array([0.12,0.04,0.22]))
    return [pose(0.16), pose(0.42)]

def ex_plank():
    high = side_plank_base(0.28)
    for s,e,w in (("ls","le","lw"),("rs","re","rw")):
        x = high[s][0]
        high[e] = np.array([x, 0.06, 0.22])
        high[w] = np.array([x, 0.05, 0.40])
        high[s] = np.array([x, 0.28, 0.22])
    high["chest"] = np.array([0.0, 0.28, 0.22])
    high["head"] = np.array([0.0, 0.26, 0.48])
    low = {k: v.copy() for k,v in high.items()}
    low["pelvis"] = low["pelvis"]+(0,-0.04,0)
    low["lh"] = low["lh"]+(0,-0.03,0)
    low["rh"] = low["rh"]+(0,-0.03,0)
    return [high, low]

def ex_superman():
    def pose(lift):
        pel = np.array([0.0, 0.10, 0.0])
        return dict(pelvis=pel,
            chest=np.array([0.0, 0.10+lift*0.10, 0.26]),
            head=np.array([0.0, 0.12+lift*0.14, 0.50]),
            ls=np.array([-0.16, 0.10+lift*0.12, 0.30]), rs=np.array([0.16, 0.10+lift*0.12, 0.30]),
            le=np.array([-0.20, 0.10+lift*0.16, 0.52]), re=np.array([0.20, 0.10+lift*0.16, 0.52]),
            lw=np.array([-0.18, 0.10+lift*0.20, 0.74]), rw=np.array([0.18, 0.10+lift*0.20, 0.74]),
            lh=np.array([-0.09, 0.10, -0.04]), rh=np.array([0.09, 0.10, -0.04]),
            lk=np.array([-0.10, 0.10+lift*0.10, -0.42]), rk=np.array([0.10, 0.10+lift*0.10, -0.42]),
            la=np.array([-0.10, 0.08+lift*0.16, -0.78]), ra=np.array([0.10, 0.08+lift*0.16, -0.78]),
            lt=np.array([-0.10, 0.08+lift*0.18, -0.88]), rt=np.array([0.10, 0.08+lift*0.18, -0.88]))
    return [pose(0.15), pose(1.0)]

def ex_mountain_climber():
    base = side_plank_base(0.30)
    for s,e,w,x in (("ls","le","lw",-0.16),("rs","re","rw",0.16)):
        base[s]=np.array([x,0.31,0.36]); base[e]=np.array([x,0.18,0.34]); base[w]=np.array([x,0.04,0.38])
    a,b = {k:v.copy() for k,v in base.items()}, {k:v.copy() for k,v in base.items()}
    a["lk"],a["la"],a["lt"] = np.array([-0.08,0.22,0.18]), np.array([-0.08,0.12,0.10]), np.array([-0.08,0.08,0.02])
    a["rk"],a["ra"],a["rt"] = np.array([0.10,0.28,-0.44]), np.array([0.10,0.06,-0.82]), np.array([0.10,0.05,-0.92])
    b["rk"],b["ra"],b["rt"] = np.array([0.08,0.22,0.18]), np.array([0.08,0.12,0.10]), np.array([0.08,0.08,0.02])
    b["lk"],b["la"],b["lt"] = np.array([-0.10,0.28,-0.44]), np.array([-0.10,0.06,-0.82]), np.array([-0.10,0.05,-0.92])
    return [a,b]

def ex_split_squat(rear_elev=0.0):
    def pose(down):
        p = standing(stance=0.08)
        fy = 0.08
        p["lh"]=np.array([-0.08, 0.90-down*0.32, 0.22]); p["lk"]=np.array([-0.08, 0.50-down*0.18, 0.32])
        p["la"]=np.array([-0.08, fy, 0.22]); p["lt"]=np.array([-0.08, 0.04, 0.32])
        p["rh"]=np.array([0.08, 0.90-down*0.32, -0.22]); p["rk"]=np.array([0.10, 0.52-down*0.08, -0.28])
        p["ra"]=np.array([0.10, fy+rear_elev, -0.38]); p["rt"]=np.array([0.10, fy+rear_elev-0.02, -0.28])
        p["pelvis"]=np.array([0.0, 0.92-down*0.32, 0.0])
        p["chest"]=np.array([0.0, 1.18-down*0.30, 0.06]); p["head"]=np.array([0.0, 1.44-down*0.28, 0.08])
        p["ls"]=np.array([-0.18, 1.20-down*0.30, 0.04]); p["rs"]=np.array([0.18, 1.20-down*0.30, 0.04])
        p["le"]=np.array([-0.22, 0.95-down*0.2, 0.02]); p["re"]=np.array([0.22, 0.95-down*0.2, 0.02])
        p["lw"]=np.array([-0.20, 0.72-down*0.1, 0.00]); p["rw"]=np.array([0.20, 0.72-down*0.1, 0.00])
        return p
    return [pose(0.05), pose(1.0)]

def ex_lateral_lunge():
    stand = standing(stance=0.14)
    L = standing(stance=0.14)
    L["pelvis"]=np.array([0.18,0.62,0.0]); L["chest"]=np.array([0.16,0.88,0.04]); L["head"]=np.array([0.16,1.14,0.06])
    L["rh"]=np.array([0.38,0.60,0.0]); L["rk"]=np.array([0.48,0.32,0.08]); L["ra"]=np.array([0.52,0.08,0.0]); L["rt"]=np.array([0.54,0.04,0.10])
    L["lh"]=np.array([-0.06,0.62,0.0]); L["lk"]=np.array([-0.18,0.36,0.02]); L["la"]=np.array([-0.28,0.08,0.0]); L["lt"]=np.array([-0.30,0.04,0.10])
    L["ls"]=np.array([-0.06,0.90,0.04]); L["rs"]=np.array([0.34,0.90,0.04])
    L["le"]=np.array([-0.10,0.70,0.16]); L["re"]=np.array([0.40,0.70,0.16])
    L["lw"]=np.array([-0.10,0.62,0.34]); L["rw"]=np.array([0.40,0.62,0.34])
    return [stand, L]

def ex_donkey_kick():
    def base():
        return dict(pelvis=np.array([0.0,0.42,0.0]), chest=np.array([0.0,0.42,0.30]), head=np.array([0.0,0.36,0.54]),
            ls=np.array([-0.14,0.40,0.32]), rs=np.array([0.14,0.40,0.32]),
            le=np.array([-0.14,0.22,0.30]), re=np.array([0.14,0.22,0.30]),
            lw=np.array([-0.14,0.05,0.32]), rw=np.array([0.14,0.05,0.32]),
            lh=np.array([-0.10,0.42,-0.02]), rh=np.array([0.10,0.42,-0.02]),
            lk=np.array([-0.10,0.22,-0.06]), rk=np.array([0.10,0.22,-0.06]),
            la=np.array([-0.10,0.06,-0.04]), ra=np.array([0.10,0.06,-0.04]),
            lt=np.array([-0.10,0.04,0.06]), rt=np.array([0.10,0.04,0.06]))
    a,b = base(), base()
    b["rk"]=np.array([0.10,0.55,-0.28]); b["ra"]=np.array([0.10,0.72,-0.48]); b["rt"]=np.array([0.10,0.78,-0.56])
    b["rh"]=np.array([0.10,0.46,-0.04])
    return [a,b]

def ex_calf_raise():
    low, high = standing(), standing()
    for k in ("la","ra"): high[k] = high[k]+(0,0.08,-0.02)
    for k in ("lt","rt"): high[k] = np.array([high[k][0], 0.04, 0.10])
    for k in ("pelvis","chest","head","ls","rs","le","re","lw","rw","lh","rh","lk","rk"):
        high[k] = high[k]+(0,0.08,0)
    return [low, high]

def ex_crunch():
    def pose(curl):
        return dict(pelvis=np.array([0.0,0.12,0.0]),
            chest=np.array([0.0,0.12+0.20*curl,-0.26+0.08*curl]),
            head=np.array([0.0,0.14+0.32*curl,-0.50+0.14*curl]),
            ls=np.array([-0.16,0.12+0.20*curl,-0.24]), rs=np.array([0.16,0.12+0.20*curl,-0.24]),
            le=np.array([-0.18,0.22+0.16*curl,-0.08]), re=np.array([0.18,0.22+0.16*curl,-0.08]),
            lw=np.array([-0.10,0.22+0.18*curl,0.06]), rw=np.array([0.10,0.22+0.18*curl,0.06]),
            lh=np.array([-0.10,0.12,0.04]), rh=np.array([0.10,0.12,0.04]),
            lk=np.array([-0.12,0.32,0.20]), rk=np.array([0.12,0.32,0.20]),
            la=np.array([-0.12,0.10,0.16]), ra=np.array([0.12,0.10,0.16]),
            lt=np.array([-0.12,0.06,0.26]), rt=np.array([0.12,0.06,0.26]))
    return [pose(0.05), pose(1.0)]

def ex_bicycle():
    def pose(side):
        pel=np.array([0.0,0.14,0.0]); chest=np.array([0.0,0.28,-0.22]); head=np.array([0.08*side,0.40,-0.42])
        ls,rs=np.array([-0.16,0.30,-0.20]), np.array([0.16,0.30,-0.20])
        if side>0:
            le,lw=np.array([-0.28,0.42,-0.22]), np.array([-0.10,0.48,-0.38])
            re,rw=np.array([0.10,0.34,0.02]), np.array([0.06,0.42,-0.30])
            lk,la,lt=np.array([-0.08,0.36,0.16]), np.array([-0.06,0.22,0.02]), np.array([-0.06,0.14,-0.04])
            rk,ra,rt=np.array([0.10,0.40,-0.28]), np.array([0.12,0.70,-0.22]), np.array([0.12,0.80,-0.18])
        else:
            re,rw=np.array([0.28,0.42,-0.22]), np.array([0.10,0.48,-0.38])
            le,lw=np.array([-0.10,0.34,0.02]), np.array([-0.06,0.42,-0.30])
            rk,ra,rt=np.array([0.08,0.36,0.16]), np.array([0.06,0.22,0.02]), np.array([0.06,0.14,-0.04])
            lk,la,lt=np.array([-0.10,0.40,-0.28]), np.array([-0.12,0.70,-0.22]), np.array([-0.12,0.80,-0.18])
        return dict(pelvis=pel,chest=chest,head=head,ls=ls,le=le,lw=lw,rs=rs,re=re,rw=rw,
                    lh=np.array([-0.09,0.16,0.02]), rh=np.array([0.09,0.16,0.02]),
                    lk=lk,la=la,lt=lt,rk=rk,ra=ra,rt=rt)
    return [pose(1.0), pose(-1.0)]

def ex_dead_bug():
    def pose(side):
        pel=np.array([0.0,0.10,0.0]); chest=np.array([0.0,0.12,-0.28]); head=np.array([0.0,0.12,-0.54])
        if side>0:
            ls,le,lw=np.array([-0.16,0.16,-0.26]), np.array([-0.16,0.36,-0.18]), np.array([-0.16,0.58,-0.16])
            rs,re,rw=np.array([0.16,0.16,-0.26]), np.array([0.16,0.16,-0.50]), np.array([0.16,0.16,-0.74])
            lh,lk,la,lt=np.array([-0.10,0.12,0.04]), np.array([-0.10,0.16,0.44]), np.array([-0.10,0.16,0.80]), np.array([-0.10,0.14,0.90])
            rh,rk,ra,rt=np.array([0.10,0.12,0.04]), np.array([0.10,0.36,0.16]), np.array([0.10,0.22,0.04]), np.array([0.10,0.12,0.00])
        else:
            rs,re,rw=np.array([0.16,0.16,-0.26]), np.array([0.16,0.36,-0.18]), np.array([0.16,0.58,-0.16])
            ls,le,lw=np.array([-0.16,0.16,-0.26]), np.array([-0.16,0.16,-0.50]), np.array([-0.16,0.16,-0.74])
            rh,rk,ra,rt=np.array([0.10,0.12,0.04]), np.array([0.10,0.16,0.44]), np.array([0.10,0.16,0.80]), np.array([0.10,0.14,0.90])
            lh,lk,la,lt=np.array([-0.10,0.12,0.04]), np.array([-0.10,0.36,0.16]), np.array([-0.10,0.22,0.04]), np.array([-0.10,0.12,0.00])
        return dict(pelvis=pel,chest=chest,head=head,ls=ls,le=le,lw=lw,rs=rs,re=re,rw=rw,
                    lh=lh,lk=lk,la=la,lt=lt,rh=rh,rk=rk,ra=ra,rt=rt)
    return [pose(1.0), pose(-1.0)]

def ex_leg_raise():
    def pose(up):
        ang=math.radians(8+70*up); L,S=0.42,0.40
        lh,rh=np.array([-0.08,0.12,0.04]), np.array([0.08,0.12,0.04])
        off=np.array([0.0, L*math.sin(ang), L*math.cos(ang)])
        off2=np.array([0.0, S*math.sin(ang), S*math.cos(ang)])
        return dict(pelvis=np.array([0.0,0.12,0.0]), chest=np.array([0.0,0.12,-0.28]), head=np.array([0.0,0.12,-0.54]),
            ls=np.array([-0.16,0.10,-0.24]), rs=np.array([0.16,0.10,-0.24]),
            le=np.array([-0.20,0.08,-0.04]), re=np.array([0.20,0.08,-0.04]),
            lw=np.array([-0.16,0.08,0.10]), rw=np.array([0.16,0.08,0.10]),
            lh=lh,rh=rh,lk=lh+off,rk=rh+off,la=lh+off+off2,ra=rh+off+off2,
            lt=lh+off+off2+(0,0.02,0.08), rt=rh+off+off2+(0,0.02,0.08))
    return [pose(0.0), pose(1.0)]

def ex_side_plank():
    def pose(hip):
        return dict(pelvis=np.array([0.0,hip,0.0]), chest=np.array([0.0,hip+0.02,0.28]), head=np.array([0.0,hip+0.10,0.52]),
            ls=np.array([0.0,hip+0.02,0.28]), le=np.array([0.0,0.08,0.28]), lw=np.array([0.0,0.05,0.46]),
            rs=np.array([0.0,hip+0.06,0.28]), re=np.array([0.05,hip+0.28,0.28]), rw=np.array([0.05,hip+0.50,0.28]),
            lh=np.array([0.0,hip,-0.02]), rh=np.array([0.0,hip+0.02,-0.02]),
            lk=np.array([0.0,hip-0.02,-0.42]), rk=np.array([0.0,hip,-0.42]),
            la=np.array([0.0,0.08,-0.80]), ra=np.array([0.0,0.12,-0.80]),
            lt=np.array([0.0,0.06,-0.90]), rt=np.array([0.0,0.10,-0.90]))
    return [pose(0.30), pose(0.38)]

def ex_jumping_jack():
    closed, opened = standing(stance=0.10), standing(stance=0.32)
    opened["ls"]=np.array([-0.20,1.22,0.0]); opened["rs"]=np.array([0.20,1.22,0.0])
    opened["le"]=np.array([-0.38,1.42,0.0]); opened["re"]=np.array([0.38,1.42,0.0])
    opened["lw"]=np.array([-0.48,1.64,0.0]); opened["rw"]=np.array([0.48,1.64,0.0])
    for k in ("pelvis","chest","head"): opened[k]=opened[k]+(0,0.06,0)
    opened["lh"]=np.array([-0.28,0.90,0.0]); opened["rh"]=np.array([0.28,0.90,0.0])
    opened["lk"]=np.array([-0.32,0.50,0.0]); opened["rk"]=np.array([0.32,0.50,0.0])
    opened["la"]=np.array([-0.34,0.10,0.0]); opened["ra"]=np.array([0.34,0.10,0.0])
    opened["lt"]=np.array([-0.34,0.06,0.08]); opened["rt"]=np.array([0.34,0.06,0.08])
    return [closed, opened]

def ex_high_knees():
    def pose(left_up):
        p=standing(stance=0.10)
        if left_up:
            p["lh"]=np.array([-0.08,0.96,0.04]); p["lk"]=np.array([-0.08,0.72,0.22]); p["la"]=np.array([-0.08,0.50,0.10]); p["lt"]=np.array([-0.08,0.42,0.04])
            p["re"]=np.array([0.16,1.00,0.16]); p["rw"]=np.array([0.14,1.10,0.32]); p["le"]=np.array([-0.16,0.90,-0.10]); p["lw"]=np.array([-0.16,0.72,-0.08])
        else:
            p["rh"]=np.array([0.08,0.96,0.04]); p["rk"]=np.array([0.08,0.72,0.22]); p["ra"]=np.array([0.08,0.50,0.10]); p["rt"]=np.array([0.08,0.42,0.04])
            p["le"]=np.array([-0.16,1.00,0.16]); p["lw"]=np.array([-0.14,1.10,0.32]); p["re"]=np.array([0.16,0.90,-0.10]); p["rw"]=np.array([0.16,0.72,-0.08])
        for k in ("pelvis","chest","head"): p[k]=p[k]+(0,0.04,0)
        return p
    return [pose(True), pose(False)]

def ex_burpee():
    stand=standing()
    jump=standing()
    for k in jump: jump[k]=jump[k]+(0,0.22,0)
    jump["ls"]=np.array([-0.18,1.46,0.0]); jump["rs"]=np.array([0.18,1.46,0.0])
    jump["le"]=np.array([-0.20,1.70,0.0]); jump["re"]=np.array([0.20,1.70,0.0])
    jump["lw"]=np.array([-0.18,1.94,0.0]); jump["rw"]=np.array([0.18,1.94,0.0])
    squat_h={k:v.copy() for k,v in ex_squat()[1].items()}
    squat_h["le"]=np.array([-0.16,0.28,0.18]); squat_h["re"]=np.array([0.16,0.28,0.18])
    squat_h["lw"]=np.array([-0.16,0.04,0.22]); squat_h["rw"]=np.array([0.16,0.04,0.22])
    plank=side_plank_base(0.30)
    for s,e,w,x in (("ls","le","lw",-0.16),("rs","re","rw",0.16)):
        plank[s]=np.array([x,0.30,0.36]); plank[e]=np.array([x,0.18,0.34]); plank[w]=np.array([x,0.04,0.38])
    return [stand, squat_h, plank, squat_h, jump]

def ex_chair_dip():
    def pose(down):
        # hips in front of and below the seat; hands planted on the front edge
        seat_y, seat_z = 0.48, 0.28
        y = 0.50 - 0.20*down
        z = 0.02 - 0.04*down
        return dict(pelvis=np.array([0.0,y,z]), chest=np.array([0.0,y+0.26,z-0.04]), head=np.array([0.0,y+0.52,z-0.02]),
            ls=np.array([-0.18,y+0.20,z+0.04]), rs=np.array([0.18,y+0.20,z+0.04]),
            le=np.array([-0.22,seat_y-0.02+0.04*(1-down),seat_z-0.02]), re=np.array([0.22,seat_y-0.02+0.04*(1-down),seat_z-0.02]),
            lw=np.array([-0.20,seat_y,seat_z]), rw=np.array([0.20,seat_y,seat_z]),
            lh=np.array([-0.09,y-0.02,z+0.02]), rh=np.array([0.09,y-0.02,z+0.02]),
            lk=np.array([-0.11,y-0.18,z+0.28]), rk=np.array([0.11,y-0.18,z+0.28]),
            la=np.array([-0.11,y-0.10,z+0.58]), ra=np.array([0.11,y-0.10,z+0.58]),
            lt=np.array([-0.11,y-0.08,z+0.68]), rt=np.array([0.11,y-0.08,z+0.68]))
    return [pose(0.0), pose(1.0)]

def ex_wall_sit():
    def pose(pulse):
        y=0.58+0.03*pulse
        return dict(pelvis=np.array([0.0,y,-0.04]), chest=np.array([0.0,y+0.26,-0.06]), head=np.array([0.0,y+0.52,-0.02]),
            ls=np.array([-0.18,y+0.24,0.02]), rs=np.array([0.18,y+0.24,0.02]),
            le=np.array([-0.16,y+0.02,0.06]), re=np.array([0.16,y+0.02,0.06]),
            lw=np.array([-0.14,y-0.08,0.16]), rw=np.array([0.14,y-0.08,0.16]),
            lh=np.array([-0.10,y-0.02,0.0]), rh=np.array([0.10,y-0.02,0.0]),
            lk=np.array([-0.12,0.32,0.22]), rk=np.array([0.12,0.32,0.22]),
            la=np.array([-0.12,0.08,0.08]), ra=np.array([0.12,0.08,0.08]),
            lt=np.array([-0.12,0.04,0.18]), rt=np.array([0.12,0.04,0.18]))
    return [pose(0.0), pose(1.0)]

def ex_pull_up(chin=False):
    def pose(up):
        bar_y=2.05; wr_y=bar_y-0.02
        if not up:
            pel=np.array([0.0,0.95,0.0]); chest=np.array([0.0,1.22,0.02]); head=np.array([0.0,1.48,0.02])
            ls,rs=np.array([-0.18,1.28,0.0]), np.array([0.18,1.28,0.0])
            le,re=np.array([-0.22,1.62,0.0]), np.array([0.22,1.62,0.0])
        else:
            pel=np.array([0.0,1.42,0.04]); chest=np.array([0.0,1.68,0.06]); head=np.array([0.0,1.92,0.04])
            ls,rs=np.array([-0.18,1.74,0.02]), np.array([0.18,1.74,0.02])
            le,re=np.array([-0.26,1.88,-0.04]), np.array([0.26,1.88,-0.04])
            if chin:
                chest, head = chest+(0,0.02,0.04), head+(0,0.02,0.04)
        lw,rw=np.array([-0.20,wr_y,0.0]), np.array([0.20,wr_y,0.0])
        lh,rh=np.array([-0.09,pel[1]-0.02,0.0]), np.array([0.09,pel[1]-0.02,0.0])
        lk,rk=np.array([-0.10,pel[1]-0.40,0.04]), np.array([0.10,pel[1]-0.40,0.04])
        la,ra=np.array([-0.08,pel[1]-0.72,-0.04]), np.array([0.08,pel[1]-0.72,-0.04])
        lt,rt=np.array([-0.08,pel[1]-0.76,0.04]), np.array([0.08,pel[1]-0.76,0.04])
        if up:
            lk,rk=lk+(0,0.06,0.08), rk+(0,0.06,0.08)
        return dict(pelvis=pel,chest=chest,head=head,ls=ls,le=le,lw=lw,rs=rs,re=re,rw=rw,
                    lh=lh,lk=lk,la=la,lt=lt,rh=rh,rk=rk,ra=ra,rt=rt)
    return [pose(False), pose(True)]

def ex_russian_twist():
    def pose(side):
        return dict(pelvis=np.array([0.0,0.28,0.0]),
            chest=np.array([0.10*side,0.52,-0.12]), head=np.array([0.16*side,0.76,-0.16]),
            ls=np.array([-0.14+0.08*side,0.54,-0.04+0.12*side]), rs=np.array([0.14+0.08*side,0.54,-0.04+0.12*side]),
            le=np.array([-0.06+0.16*side,0.50,0.16+0.10*side]), re=np.array([0.06+0.16*side,0.50,0.16+0.10*side]),
            lw=np.array([0.10*side,0.48,0.30+0.08*side]), rw=np.array([0.16*side,0.48,0.32+0.08*side]),
            lh=np.array([-0.10,0.26,0.04]), rh=np.array([0.10,0.26,0.04]),
            lk=np.array([-0.12,0.22,0.36]), rk=np.array([0.12,0.22,0.36]),
            la=np.array([-0.12,0.10,0.62]), ra=np.array([0.12,0.10,0.62]),
            lt=np.array([-0.12,0.08,0.72]), rt=np.array([0.12,0.08,0.72]))
    return [pose(-1.0), pose(1.0)]

def ex_cat_cow():
    def pose(cow):
        k=1.0 if cow else -1.0
        return dict(pelvis=np.array([0.0,0.42+0.06*(-k),0.0]), chest=np.array([0.0,0.42+0.08*k,0.30]),
            head=np.array([0.0,0.36+0.16*k,0.54]),
            ls=np.array([-0.14,0.40,0.32]), rs=np.array([0.14,0.40,0.32]),
            le=np.array([-0.14,0.22,0.30]), re=np.array([0.14,0.22,0.30]),
            lw=np.array([-0.14,0.05,0.32]), rw=np.array([0.14,0.05,0.32]),
            lh=np.array([-0.10,0.42+0.04*(-k),-0.02]), rh=np.array([0.10,0.42+0.04*(-k),-0.02]),
            lk=np.array([-0.10,0.22,-0.04]), rk=np.array([0.10,0.22,-0.04]),
            la=np.array([-0.10,0.06,-0.02]), ra=np.array([0.10,0.06,-0.02]),
            lt=np.array([-0.10,0.04,0.08]), rt=np.array([0.10,0.04,0.08]))
    return [pose(True), pose(False)]

def ex_wall_push():
    def pose(down):
        p=standing()
        p["pelvis"]=np.array([0.0,0.92,0.10]); p["chest"]=np.array([0.0,1.18,0.18+0.10*down]); p["head"]=np.array([0.0,1.44,0.22+0.10*down])
        p["ls"]=np.array([-0.16,1.30,0.32+0.08*down]); p["rs"]=np.array([0.16,1.30,0.32+0.08*down])
        p["le"]=np.array([-0.16,1.22-0.06*down,0.48]); p["re"]=np.array([0.16,1.22-0.06*down,0.48])
        p["lw"]=np.array([-0.16,1.35,0.62]); p["rw"]=np.array([0.16,1.35,0.62])
        if down:
            p["chest"]=p["chest"]+(0,0,0.10); p["head"]=p["head"]+(0,0,0.10); p["pelvis"]=p["pelvis"]+(0,0,0.06)
            p["le"]=np.array([-0.22,1.18,0.50]); p["re"]=np.array([0.22,1.18,0.50])
        return p
    return [pose(0.0), pose(1.0)]

EXERCISES = {
    "push-up": dict(cam="side", highlight=["chest","triceps"], build=lambda: ex_push_up()),
    "wide-push-up": dict(cam="side", highlight=["chest"], build=lambda: ex_push_up(wide=0.26)),
    "diamond-push-up": dict(cam="side", highlight=["triceps","chest"], build=lambda: ex_push_up(wide=0.16, close=True)),
    "pike-push-up": dict(cam="side", highlight=["shoulders"], build=lambda: ex_push_up(pike=True)),
    "incline-push-up": dict(cam="side", highlight=["chest"], props=[("block",{"pos":(0.0,0.22,0.38)})], build=lambda: ex_push_up(incline=0.22)),
    "wall-push-up": dict(cam="side", highlight=["chest"], props=[("wall",{"z":0.66,"h":2.0})], build=ex_wall_push),
    "bodyweight-squat": dict(cam="qtr", highlight=["quads","glutes"], build=ex_squat),
    "glute-bridge": dict(cam="side", highlight=["glutes","hamstrings"], build=ex_glute_bridge),
    "plank": dict(cam="side", highlight=["abdomen"], build=ex_plank, hold=0.2),
    "superman": dict(cam="side", highlight=["lowerback","glutes"], build=ex_superman),
    "mountain-climber": dict(cam="side", highlight=["abdomen","quads"], build=ex_mountain_climber, mode="loop"),
    "split-squat": dict(cam="side", highlight=["quads","glutes"], build=lambda: ex_split_squat()),
    "bulgarian-split-squat": dict(cam="side", highlight=["quads","glutes"], props=[("bench",{"pos":(0.10,0.42,-0.50)})], build=lambda: ex_split_squat(rear_elev=0.40)),
    "lateral-lunge": dict(cam="front", highlight=["quads","glutes"], build=ex_lateral_lunge),
    "donkey-kick": dict(cam="side", highlight=["glutes"], build=ex_donkey_kick),
    "calf-raise": dict(cam="qtr", highlight=["calves"], build=ex_calf_raise),
    "crunch": dict(cam="side", highlight=["abdomen"], build=ex_crunch),
    "bicycle-crunch": dict(cam="qtr", highlight=["abdomen","obliques"], build=ex_bicycle, mode="loop"),
    "dead-bug": dict(cam="qtr", highlight=["abdomen"], build=ex_dead_bug, mode="loop"),
    "lying-leg-raise": dict(cam="side", highlight=["abdomen"], build=ex_leg_raise),
    "side-plank": dict(cam="side", highlight=["obliques"], build=ex_side_plank, hold=0.2),
    "jumping-jack": dict(cam="front", highlight=["quads","shoulders"], build=ex_jumping_jack),
    "high-knees": dict(cam="qtr", highlight=["quads"], build=ex_high_knees, mode="loop"),
    "burpee": dict(cam="side", highlight=["quads","chest","abdomen"], build=ex_burpee, mode="loop", still=0.82),
    "chair-dip": dict(cam="side", highlight=["triceps","chest"], props=[("chair",{"pos":(0.0,0.48,0.32)})], build=ex_chair_dip),
    "wall-sit": dict(cam="side", highlight=["quads"], props=[("wall_side",{"x":0.0,"z0":-0.35,"z1":-0.15,"h":2.0})], build=ex_wall_sit, hold=0.25),
    "pull-up": dict(cam="front", highlight=["back","biceps"], props=[("bar",{"y":2.05,"w":0.55})], build=lambda: ex_pull_up(False)),
    "chin-up": dict(cam="front", highlight=["biceps","back"], props=[("bar",{"y":2.05,"w":0.55})], build=lambda: ex_pull_up(True)),
    "russian-twist": dict(cam="qtr", highlight=["abdomen","obliques"], build=ex_russian_twist, mode="loop"),
    "cat-cow-stretch": dict(cam="side", highlight=["back"], build=ex_cat_cow),
}
