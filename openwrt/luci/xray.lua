-- /usr/lib/lua/luci/controller/xray.lua

module("luci.controller.xray", package.seeall)

function index()
    if not nixio.fs.access("/etc/init.d/xray") then
        return
    end

    entry({"admin", "services", "xray"},
        alias("admin", "services", "xray", "panel"),
        _("Xray Panel"), 60)

    entry({"admin", "services", "xray", "panel"},
        template("xray/panel"),
        _("Xray Panel"), 1).leaf = true

    -- AJAX endpoints
    entry({"admin", "services", "xray", "status_json"},
        call("status_json")).leaf = true

    entry({"admin", "services", "xray", "logs"},
        call("logs_handler")).leaf = true

    entry({"admin", "services", "xray", "save_config"},
        call("save_config")).leaf = true

    entry({"admin", "services", "xray", "upload_config"},
        call("upload_config")).leaf = true

    entry({"admin", "services", "xray", "configs_json"},
        call("configs_json")).leaf = true

    entry({"admin", "services", "xray", "set_active_config"},
        call("set_active_config")).leaf = true

    entry({"admin", "services", "xray", "action"},
        call("action_handler")).leaf = true

    entry({"admin","services","xray","get_config"}, call("get_config")).leaf = true
end

local CONFIGS_FILE = "/etc/xray/configs"

function get_config()
    local name = luci.http.formvalue("name")
    if not name then
        luci.http.status(400, "Missing config name")
        return
    end
    local path = "/etc/xray/" .. name
    if not nixio.fs.access(path) then
        luci.http.status(404, "File not found")
        return
    end
    local f = io.open(path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        luci.http.prepare_content("application/json")
        luci.http.write_json({content = content})
    else
        luci.http.status(500, "Cannot read file")
    end
end

function configs_json()
    local configs = {}
    if nixio.fs.access(CONFIGS_FILE) then
        for line in io.lines(CONFIGS_FILE) do
            line = line:match("^%s*(.-)%s*$") -- trim
            if line ~= "" and not line:match("^#") then
                local idx, path = line:match("^(%d+)=(.+)$")
                if idx and path then
                    configs[#configs+1] = {id=idx, path=path}
                end
            end
        end
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(configs)
end

function set_active_config()
    local id = luci.http.formvalue("id")
    if not id then
        luci.http.status(400, "Missing id")
        return
    end

    local configs = {}
    local activePath = nil
    for line in io.lines(CONFIGS_FILE) do
        local idx, path = line:match("^(%d+)=(.+)$")
        if idx and path then
            if idx == id then
                activePath = path
            else
                configs[#configs+1] = path
            end
        end
    end

    -- теперь перезаписываем, первый всегда активный
    local f = io.open(CONFIGS_FILE,"w+")
    if f then
        f:write("1=" .. activePath .. "\n")
        for i,path in ipairs(configs) do
            f:write((i+1).."=" .. path .. "\n")
        end
        f:close()
    end

    luci.http.redirect(luci.dispatcher.build_url("admin/services/xray/panel"))
end


function status_json()
    local output = luci.sys.exec("/usr/bin/xray_status.sh")
    local running, pid, cfg = false, "", ""
    for line in output:gmatch("[^\r\n]+") do
        if line:match("^running") then running = true end
        if line:match("^pid=") then pid = line:match("^pid=(%d+)") end
        if line:match("^config=") then cfg = line:match("^config=(.+)") end
    end

    local content = ""
    if cfg and nixio.fs.access("/etc/xray/"..cfg) then
        local f = io.open("/etc/xray/"..cfg,"r")
        if f then content = f:read("*a"); f:close() end
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json({
        running = running,
        pid = pid or "",
        config = cfg or "",
        config_content = content
    })
end


function logs_handler()
    luci.http.prepare_content("text/plain")
    local logs = luci.sys.exec("[ -f /var/log/xray.log ] && tail -n 50 /var/log/xray.log || echo 'No logs.'")
    luci.http.write(logs)
end

function refresh_configuration_list(new_config)
    local lines = {}
    local path = "/etc/xray/configs"
    
    -- Проверяем существует ли файл
    local f = io.open(path, "r")
    if f then
        for line in f:lines() do
            local idx, path = line:match("^(%d+)=(.+)$")
            if idx and path then
                table.insert(lines, {id=idx, path=path})
            end
        end
        f:close()
    end
    
    -- Записываем обновленный список
    local f = io.open(path, "w")
    if f then
        -- Записываем существующие конфиги
        for _, item in ipairs(lines) do
            f:write(item.id .. "=" .. item.path .. "\n")
        end
        
        -- Добавляем новый конфиг если есть
        if new_config then
            local new_id = #lines + 1
            f:write(tostring(new_id) .. "=" .. new_config .. "\n")
        end
        
        f:close()
    end
end

function save_config()
    local config_name = luci.http.formvalue("config_name")
    local content = luci.http.formvalue("config_content")
    if config_name and content then
        local path = "/etc/xray/" .. config_name
        local f = io.open(path, "w+")
        if f then
            f:write(content)
            f:close()
        end
        refresh_configuration_list(config_name)
    end
    luci.http.redirect(luci.dispatcher.build_url("admin/services/xray/panel"))
end

function upload_config()
    local file = luci.http.formvalue("upload_file")
    if file then
        local path = "/etc/xray/" .. file.filename
        local f = io.open(path, "w+")
        if f then
            f:write(file.file:read("*a"))
            f:close()
        end
    end
    luci.http.redirect(luci.dispatcher.build_url("admin/services/xray/panel"))
end

function action_handler()
    local action = luci.http.formvalue("exec")
    if action == "start" then
        luci.sys.call("/etc/init.d/xray start >/dev/null 2>&1")
    elseif action == "stop" then
        luci.sys.call("/etc/init.d/xray stop >/dev/null 2>&1")
    elseif action == "restart" then
        luci.sys.call("sh /etc/xray/restart.sh >/dev/null 2>&1")
    end
    luci.http.redirect(luci.dispatcher.build_url("admin/services/xray/panel"))
end
