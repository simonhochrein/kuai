---@meta

---@class Target
---@field name string
---@field files string

---@class Config


---@param opts [Target|Config]
function build (opts) end

function executable() end

---@class LibraryOpts
---@field files [string]

---Add library definition to build
---@param name string
---@return function<LibraryOpts>
function library(name) end

---@param opts LibraryOpts
function libraryOpts(opts) end
