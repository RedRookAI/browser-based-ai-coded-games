import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
const {chromium}=await import(process.env.PLAYWRIGHT_MODULE||'playwright-core');
const exportRoot=path.resolve(process.argv[2]);
const evidence=path.resolve(process.argv[3]);fs.mkdirSync(evidence,{recursive:true});
const types={'.html':'text/html','.wasm':'application/wasm','.js':'application/javascript','.png':'image/png'};
const server=http.createServer((req,res)=>{const name=new URL(req.url,'http://local').pathname;const file=path.resolve(exportRoot,'.'+(name==='/'?'/index.html':name));if(!file.startsWith(exportRoot+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return}res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');fs.createReadStream(file).pipe(res)});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
let browser;const errors=[],checks=[];
try{
 browser=await chromium.launch({executablePath:process.env.BROWSER_EXECUTABLE||'/usr/bin/google-chrome',headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const page=await browser.newPage({viewport:{width:1000,height:700}});
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});page.on('requestfailed',r=>errors.push(r.url()+': '+r.failure()?.errorText));
 await page.goto('http://127.0.0.1:'+server.address().port+'/');await page.waitForFunction(()=>window.__tv_robot_state?.grounded,{timeout:60000});
 const state=()=>page.evaluate(()=>window.__tv_robot_state);
 const test=(name,ok,detail)=>{assert.ok(ok,name+' '+JSON.stringify(detail??''));checks.push(name)};
 await page.locator('#canvas').click({position:{x:300,y:500}});
 let initial=await state();await page.keyboard.down('d');await page.waitForTimeout(650);await page.keyboard.up('d');let moved=await state();test('real keyboard movement',moved.player_feet.x>initial.player_feet.x+60,{initial,moved});
 await page.waitForTimeout(300);await page.keyboard.press('Space');await page.waitForTimeout(150);test('real jump rises',(await state()).player_feet.y<560);await page.waitForTimeout(1300);
 await page.keyboard.down('s');await page.waitForTimeout(80);test('crouch pose state',(await state()).crouched);await page.keyboard.up('s');
 await page.mouse.click(120,100,{button:'right'});await page.waitForTimeout(700);test('right-click hook attaches',(await state()).hook_state==='attached',await state());await page.keyboard.press('r');await page.waitForTimeout(80);test('R releases hook',(await state()).hook_state==='idle');
 await page.keyboard.press('Enter');await page.waitForTimeout(100);test('restart returns spawn',Math.abs((await state()).player_feet.x-380)<3);
 // Verify the full world-grapple cycle, not only its attached flag. The vertical
 // lane at x=380 is clear of the platform and initial creature spawn positions.
 await page.mouse.click(380,60,{button:'right'});
 await page.waitForFunction(()=>window.__tv_robot_state.hook_state==='attached',{timeout:5000});
 let attached=await state();test('ceiling grapple acquires world',attached.hook_target==='',attached);
 await page.waitForFunction(()=>window.__tv_robot_state.player_feet.y<510,{timeout:5000});
 let lifted=await state();test('ceiling winch lifts player',lifted.hook_state==='attached'&&!lifted.grounded&&lifted.player_velocity.y< -100,lifted);
 // Sample the release transition inside the page: remote round-trip time under
 // software rendering can consume the entire brief upward coast.
 await page.evaluate(()=>{
  window.__grappleReleaseProbe={};
  const sample=()=>{
   const s=window.__tv_robot_state,p=window.__grappleReleaseProbe;
   if(s.hook_state==='idle'){
    if(!p.first){p.first=structuredClone(s);p.until=performance.now()+250;p.minY=s.player_feet.y;}
    p.minY=Math.min(p.minY,s.player_feet.y);
    if(performance.now()>=p.until){p.done=true;return;}
   }
   requestAnimationFrame(sample);
  };requestAnimationFrame(sample);
 });
 await page.mouse.click(380,60,{button:'right'});
 await page.waitForFunction(()=>window.__grappleReleaseProbe.done,{timeout:5000});
 let releaseProbe=await page.evaluate(()=>window.__grappleReleaseProbe);
 test('right-click releases while retaining upward momentum',releaseProbe.first.player_velocity.y<0,releaseProbe);
 test('released player coasts upward',releaseProbe.minY<releaseProbe.first.player_feet.y,releaseProbe);
 await page.mouse.click(380,60,{button:'right'});
 await page.waitForFunction(()=>window.__tv_robot_state.hook_state==='attached',{timeout:5000});
 test('grapple fires and attaches again after release',(await state()).hook_state==='attached');
 await page.keyboard.press('r');await page.waitForFunction(()=>window.__tv_robot_state.hook_state==='idle',{timeout:2000});
 test('R releases the second grapple',(await state()).hook_state==='idle');
 await page.keyboard.press('Enter');await page.waitForTimeout(100);

 await page.mouse.click(620,660);await page.waitForTimeout(100);test('HUD movement button does not punch',(await state()).punch_phase<0,await state());
 await page.mouse.click(620,660,{button:'right'});await page.waitForTimeout(80);test('HUD right click does not grapple',(await state()).hook_state==='idle');
 await page.mouse.click(800,400);await page.waitForTimeout(80);test('normal world click still punches',(await state()).punch_phase>=0);
 await page.keyboard.press('Enter');await page.waitForTimeout(100);
 await page.screenshot({path:path.join(evidence,'desktop.png')});
 await page.setViewportSize({width:430,height:850});await page.mouse.move(215,425);await page.waitForTimeout(120);let narrow=await state();test('narrow resize keeps logical world',Math.abs(narrow.player_feet.x-380)<5);test('aim maps through stretch',Math.abs(narrow.aim.x-500)<5&&Math.abs(narrow.aim.y-350)<5,narrow.aim);await page.screenshot({path:path.join(evidence,'narrow.png')});
 test('no engine/browser errors',errors.length===0,errors);
 const result={status:'passed',checks,errors,rendering:'software WebGL; actual target device not tested',browser:browser.version()};fs.writeFileSync(path.join(evidence,'browser.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result));
}catch(e){fs.writeFileSync(path.join(evidence,'failure.json'),JSON.stringify({checks,errors,error:String(e)},null,2));throw e}finally{await browser?.close();await new Promise(r=>server.close(r))}
