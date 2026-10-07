local root=app.params["root"]
for _,name in ipairs(app.fs.listFiles(root.."/assets/source/aseprite")) do
 if app.fs.fileExtension(name)=="aseprite" then
  local sprite=app.open(root.."/assets/source/aseprite/"..name)
  sprite:saveCopyAs(root.."/assets/exported/"..app.fs.fileTitle(name)..".png")
  sprite:close()
 end
end
