local root=app.params["root"]
app.fs.makeAllDirectories(root.."/assets/source/aseprite")
app.fs.makeAllDirectories(root.."/assets/exported")
local function c(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
local ink=c("20242c");local light=c("fff1db")
local function rect(im,x,y,w,h,col)
 for yy=math.max(0,y),math.min(im.height-1,y+h-1) do for xx=math.max(0,x),math.min(im.width-1,x+w-1) do im:drawPixel(xx,yy,col) end end
end
local function line(im,x,y,ex,ey,col)
 local steps=math.max(math.abs(ex-x),math.abs(ey-y)); for i=0,steps do local t=steps==0 and 0 or i/steps;rect(im,math.floor(x+(ex-x)*t),math.floor(y+(ey-y)*t),1,1,col) end
end
local function ellipse(im,x,y,rx,ry,col)
 for yy=-ry,ry do for xx=-rx,rx do if xx*xx/(rx*rx)+yy*yy/(ry*ry)<=1 then rect(im,x+xx,y+yy,1,1,col) end end end
end
local function diamond(im,x,y,r,col)
 for yy=-r,r do local w=r-math.abs(yy);rect(im,x-w,y+yy,w*2+1,1,col) end
end
local function layer(s,name)
 local l=s:newLayer();l.name=name;local im=Image(s.width,s.height);local cel=s:newCel(l,1,im);return cel.image
end
local function save(s,name)
 s:saveAs(root.."/assets/source/aseprite/"..name..".aseprite")
 s:saveCopyAs(root.."/assets/exported/"..name..".png");s:close()
end


local s=Sprite(32,40);s.layers[1].name="Glass shaker";local im=s.cels[1].image
rect(im,7,10,18,27,ink);rect(im,9,12,14,23,c("68b5ce"));rect(im,11,14,3,15,c("fff1db"));rect(im,14,32,7,2,c("3d749c"))
local sweets=layer(s,"Candy sugar crystals")
for _,p in ipairs({{14,28},{20,27},{17,21},{20,16}}) do diamond(sweets,p[1],p[2],2,c("f4c76b")) end
local lid=layer(s,"Metal lid and shake marks")
rect(lid,6,6,20,7,ink);rect(lid,8,7,16,4,c("f4c76b"));for x=10,22,4 do rect(lid,x,8,2,1,ink) end
line(lid,2,14,2,24,c("fff1db"));line(lid,29,9,29,19,c("fff1db"))
save(s,"sugar_shaker")
