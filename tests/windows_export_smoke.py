"""Windows release EXE smoke test using native window messages and isolated --test saves."""
import ctypes,json,os,subprocess,time
from ctypes import wintypes
from pathlib import Path
root=Path(__file__).resolve().parents[1]
exe=root/'builds/windows/SugarRush.exe'
startup=subprocess.STARTUPINFO()
startup.dwFlags=subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow=0
user32=ctypes.windll.user32
user32.SendMessageW.argtypes=[wintypes.HWND,wintypes.UINT,wintypes.WPARAM,wintypes.LPARAM]
user32.SendMessageW.restype=wintypes.LPARAM
out=root/'builds/windows-smoke.log'
err=root/'builds/windows-smoke-errors.log'
with out.open('w') as stdout,err.open('w') as stderr:
 process=subprocess.Popen([str(exe),'--audio-driver','Dummy','--resolution','1152x720','--','--test'],startupinfo=startup,stdout=stdout,stderr=stderr)
 path=Path(os.environ['APPDATA'])/'Godot/app_userdata/Sugar Roguelite'/('test_run_%s.cfg'%process.pid)
 try:
  handles=[]
  @ctypes.WINFUNCTYPE(wintypes.BOOL,wintypes.HWND,wintypes.LPARAM)
  def enum(hwnd,_):
   pid=wintypes.DWORD()
   user32.GetWindowThreadProcessId(hwnd,ctypes.byref(pid))
   if pid.value==process.pid:
    title=ctypes.create_unicode_buffer(256)
    user32.GetWindowTextW(hwnd,title,256)
    if title.value.startswith('Sugar Rush'):handles.append(hwnd)
   return True
  for _ in range(40):
   user32.EnumWindows(enum,0)
   if handles:break
   time.sleep(.1)
  assert handles,'No game window'
  hwnd=handles[0]
  time.sleep(1)
  rect=wintypes.RECT()
  user32.GetClientRect(hwnd,ctypes.byref(rect))
  def click(x,y):
   factor=min(rect.right/1152,rect.bottom/720)
   x=round((rect.right-1152*factor)/2+x*factor)
   y=round((rect.bottom-720*factor)/2+y*factor)
   point=x|(y<<16)
   user32.SendMessageW(hwnd,0x200,0,point)
   user32.SendMessageW(hwnd,0x201,1,point)
   user32.SendMessageW(hwnd,0x202,0,point)
   time.sleep(.4)
  def saved(moves):
   for _ in range(40):
    if path.exists():
     text=path.read_text()
     if '"moves": %s'%moves in text:return text
    time.sleep(.1)
   raise AssertionError('Expected save with %s moves'%moves)
  click(570,453)
  click(715,662)
  initial=saved(10)
  cells=json.JSONDecoder().raw_decode(initial.split('"cells": ',1)[1])[0]
  pair=next((i,i+1) for i in range(63) if i%8!=7 and cells[i][0]==cells[i+1][0] and cells[i][2]==cells[i+1][2]==0)
  for i in pair:click(480+(i%8)*56,244+(i//8)*56)
  saved(9)
  click(830,692)
  click(575,358)
  click(575,398)
  for i in pair:click(480+(i%8)*56,244+(i//8)*56)
  saved(8)
  user32.SendMessageW(hwnd,0x10,0,0)
  assert process.wait(timeout=10)==0
  assert '"moves": 8' in path.read_text()
  print('PASS: Windows release starts, handles swaps, saves, returns to title, continues and closes cleanly')
 finally:
  if process.poll() is None:process.terminate();process.wait(timeout=10)
  if path.exists():path.unlink()
assert not err.read_text().strip(),err.read_text()
