"""Exercise the actual exported web build. Requires playwright and installed Chrome.
Set SUGAR_BROWSER_ENGINE=webkit after `python -m playwright install webkit`
to cover WebKit rendering; this does not replace testing on a physical iPhone.
Run a local server from builds/web first, then: python tests/web_export_smoke.py
No production/browser-profile save is read or changed.
"""
import asyncio, json, os, sys
from pathlib import Path
from playwright.async_api import async_playwright
URL = sys.argv[1] if len(sys.argv)>1 else "http://127.0.0.1:8765"
OUT = Path(__file__).resolve().parents[1]/"builds"/"test-captures"
OUT.mkdir(parents=True,exist_ok=True)
(OUT.parent/'.gdignore').touch()
READ_FILE = """async name=>await new Promise((resolve,reject)=>{
 const req=indexedDB.open('/userfs');
 req.onerror=()=>reject(req.error);
 req.onsuccess=()=>{const db=req.result;
 if(!db.objectStoreNames.contains('FILE_DATA')){db.close();resolve(null);return;}
 const tx=db.transaction('FILE_DATA','readonly'), store=tx.objectStore('FILE_DATA');
 const keys=store.getAllKeys();keys.onsuccess=()=>{
 const path=keys.result.find(k=>String(k).endsWith('/'+name));
 if(!path){resolve(null);return;}
 const value=store.get(path);value.onsuccess=()=>resolve(new TextDecoder().decode(value.result.contents));
 };tx.oncomplete=()=>db.close();};})"""
async def saved(page, predicate):
 for _ in range(30):
  text=await page.evaluate(READ_FILE,'run_save.cfg')
  if text and predicate(text):return text
  await page.wait_for_timeout(250)
 raise AssertionError('Expected persisted run was not found')
async def click_game(page,x,y,touch=False):
 viewport=page.viewport_size
 factor=min(viewport['width']/1152,viewport['height']/720)
 x=(viewport['width']-1152*factor)/2+x*factor
 y=(viewport['height']-720*factor)/2+y*factor
 if touch: await page.touchscreen.tap(x,y)
 else: await page.mouse.click(x,y)
 await page.wait_for_timeout(350)
async def launch(page):
 await page.locator('#play').click()
 await page.locator('#start').wait_for(state='detached',timeout=90000)
 await page.wait_for_timeout(700)
async def exercise(browser,name,width,height,touch,locale='en-US'):
 context=await browser.new_context(viewport={'width':width,'height':height},has_touch=touch,device_scale_factor=3 if touch else 1,is_mobile=touch,locale=locale)
 page=await context.new_page()
 errors=[]
 page.on('pageerror',lambda error:errors.append(str(error)))
 page.on('console',lambda message:errors.append(message.text) if message.type=='error' else None)
 await page.goto(URL)
 if width<height and width<600:
  assert await page.locator('#rotate').is_visible()
  await page.locator('#portrait').click()
 await launch(page)
 await click_game(page,570,453,touch)
 await page.screenshot(path=str(OUT/(name+'-new-run-route.png')))
 await click_game(page,715,662,touch)
 initial=await saved(page,lambda text:'"state": "playing"' in text)
 assert '"moves": 10' in initial
 cells=json.JSONDecoder().raw_decode(initial.split('"cells": ',1)[1])[0]
 pair=next((i,i+1) for i in range(63) if i%8!=7 and cells[i][0]==cells[i+1][0] and cells[i][2]==cells[i+1][2]==0)
 for i in pair:await click_game(page,480+(i%8)*56,244+(i//8)*56,touch)
 after=await saved(page,lambda text:'"moves": 9' in text)
 await click_game(page,830,692,touch)
 await click_game(page,575,358,touch)
 await click_game(page,575,398,touch)
 await page.screenshot(path=str(OUT/(name+'-continued.png')))
 assert await saved(page,lambda text:'"moves": 9' in text)==after
 await page.reload()
 if width<height and width<600:await page.locator('#portrait').click()
 await launch(page)
 await click_game(page,575,398,touch)
 # A second board action verifies Continue actually returned to the round after reload.
 for i in pair:await click_game(page,480+(i%8)*56,244+(i//8)*56,touch)
 await saved(page,lambda text:'"moves": 8' in text)
 await page.screenshot(path=str(OUT/(name+'-reloaded.png')))
 # A graphics failure must remain readable even after the loading overlay is gone.
 await page.evaluate("document.getElementById('canvas').dispatchEvent(new Event('webglcontextlost'))")
 assert await page.locator('#failure').is_visible()
 assert 'graphics connection' in await page.locator('#failure-message').inner_text()
 await page.locator('#dismiss-error').click()
 assert not await page.locator('#failure').is_visible()
 assert not errors,errors
 print('PASS:',name,'start, swap, save/title/continue, reload/continue, exact move counts; no browser errors')
 await context.close()
async def main():
 async with async_playwright() as p:
  if os.environ.get('SUGAR_BROWSER_ENGINE')=='webkit':
   browser=await p.webkit.launch(headless=True)
  else:
   browser=await p.chromium.launch(channel=os.environ.get('SUGAR_BROWSER_CHANNEL','chrome'),headless=True,args=['--mute-audio','--enable-unsafe-swiftshader'])
  for args in [('desktop',1152,720,False),('phone-landscape',844,390,True),('tablet-portrait',768,1024,True),('phone-portrait',390,844,True),('phone-hebrew',844,390,True,'he-IL'),('phone-arabic',844,390,True,'ar-SA')]:
   await exercise(browser,*args)
  await browser.close()
asyncio.run(main())
