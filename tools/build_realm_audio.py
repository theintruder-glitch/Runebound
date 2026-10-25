#!/usr/bin/env python3
"""Original deterministic ambience; no recordings, samples or external dependencies."""
import math,random,wave,struct
from pathlib import Path
RATE=16000
SECONDS=8
root=Path(__file__).resolve().parents[1]/'assets/audio'
for region in ['frostspire','blackmire','stormbreak']:
 rng=random.Random(region);samples=[];filtered=0.0
 for i in range(RATE*SECONDS):
  t=i/RATE;filtered=filtered*.96+(rng.random()*2-1)*.04
  wind=filtered*(.14+.07*math.sin(math.tau*t/8))
  if region=='blackmire':
   insect=math.sin(math.tau*1700*t)*max(0,math.sin(math.tau*t*2))**7*.014
   croak=math.sin(math.tau*(100+15*math.sin(t*14))*t)*max(0,math.cos(math.tau*(t-3)/8))**40*.035
   value=wind*.4+insect+croak
  else:
   tone=math.sin(math.tau*(86 if region=='frostspire' else 54)*t)*.018*(1+math.sin(math.tau*t/8))
   value=wind+tone
  fade=min(1,t/.2,(SECONDS-t)/.2)
  samples.append(int(max(-1,min(1,value*fade))*32767))
 with wave.open(str(root/(region+'.wav')),'wb') as out:
  out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print('Wrote three original 16 kHz mono wind/marsh ambience loops.')
