local color_utils = require("colortils.utils.colors")
local settings = require("colortils").settings
local idx = 1
local buf
local ns = vim.api.nvim_create_namespace("colortils_gradient")
local old_cursor = vim.opt.guicursor

--- Sets the marker which indeicates position on the gradient
local function set_marker()
    vim.api.nvim_buf_set_lines(
        buf,
        1,
        2,
        false,
        { string.rep(" ", math.floor(idx / 5) - 1) .. "^" }
    )
end

--- Increases index
---@param amount number
local function increase(amount)
    amount = amount or 1
    if idx >= 51 * 5 then
        return
    end
    idx = idx + amount
    idx = math.min(idx, 255)
end

--- Decreases index
---@param amount number
local function decrease(amount)
    amount = amount or 1
    if idx <= 1 then
        return
    end
    idx = idx - amount
    idx = math.max(idx, 1)
end

return function(color, color_2)
    buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = 51,
        col = 10,
        row = 5,
        style = "minimal",
        height = 3,
        border = settings.border,
    })
    vim.api.nvim_win_set_option(win, "cursorline", false)
    color_utils.display_gradient(buf, ns, 0, color, color_2, 51)
    vim.opt.guicursor = "a:ver1-Normal/Normal"
    vim.api.nvim_create_autocmd("CursorMoved", {
        callback = function()
            vim.api.nvim_win_set_cursor(win, { 2, 1 })
        end,
        buffer = buf,
    })
    vim.api.nvim_create_autocmd("BufLeave", {
        callback = function()
            vim.opt.guicursor = old_cursor
        end,
    })

    local gradient_big = require("colortils.utils.colors").gradient_colors(
        color,
        color_2,
        255
    )
    local function update()
        vim.api.nvim_set_hl(0, "ColorPickerPreview", { fg = gradient_big[idx] })
        local line
        if string.find(settings.color_preview, "%s") then
            line = string.format(settings.color_preview, gradient_big[idx])
        else
            line = settings.color_preview
        end

        set_marker()
        vim.api.nvim_buf_set_lines(buf, 2, 3, false, { line })
        vim.api.nvim_buf_add_highlight(buf, ns, "ColorPickerPreview", 2, 0, -1)
    end
    local function get_color(invalid)
        local input_color
        if invalid then
            input_color = vim.fn.input("Input a valid color > ", "#RRGGBB")
        else
            input_color = vim.fn.input("Input a color > ", "#RRGGBB")
        end
        if not input_color:match("^#%x%x%x%x%x%x$") then
            input_color = get_color(true)
        end
        return input_color
    end

    local tools = {
        ["Picker"] = function(hex_color)
            require("colortils.tools.picker")(hex_color)
        end,
        ["Gradient"] = function(hex_color)
            local second_color = get_color()
            require("colortils.tools.gradients.colors")(hex_color, second_color)
        end,
        ["Greyscale"] = function(hex_color)
            require("colortils.tools.gradients.greyscale")(hex_color)
        end,
        ["Lighten"] = function(hex_color)
            require("colortils.tools.lighten")(hex_color)
        end,
        ["Darken"] = function(hex_color)
            require("colortils.tools.darken")(hex_color)
        end,
    }

    local function export()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {})
        buf = nil
        win = nil
        vim.ui.select(
            { "Picker", "Gradient", "Greyscale", "Lighten", "Darken" },
            { prompt = "Choose tool" },
            function(item)
                tools[item](gradient_big[idx])
                idx = 1
            end
        )
    end

    local format_strings = {
        ["hex"] = function()
            return gradient_big[idx]
        end,
        ["rgb"] = function()
            local picked_color = gradient_big[idx]
            return "rgb("
                .. picked_color:sub(2, 3)
                .. ", "
                .. picked_color:sub(4, 5)
                .. ", "
                .. picked_color:sub(6, 7)
                .. ")"
        end,
        ["hsl"] = function()
            local picked_color = gradient_big[idx]
            local h, s, l = unpack(
                color_utils.rgb_to_hsl(
                    tonumber(picked_color:sub(2, 3), 16),
                    tonumber(picked_color:sub(4, 5), 16),
                    tonumber(picked_color:sub(6, 7), 16)
                )
            )
            return "hsl(" .. h .. ", " .. s .. "%, " .. l .. "%)"
        end,
    }

    vim.keymap.set("n", "l", function()
        increase()
        update()
    end, {
        buffer = buf,
        noremap = true,
    })
    vim.keymap.set("n", settings.mappings.increment_big, function()
        increase(5)
        update()
    end, {
        buffer = buf,
        noremap = true,
    })
    vim.keymap.set("n", "q", "<cmd>q<CR>", {
        buffer = buf,
        noremap = true,
    })
    vim.keymap.set("n", "E", function()
        export()
    end, {
        buffer = buf,
        noremap = true,
    })

    vim.keymap.set("n", "h", function()
        decrease()
        update()
    end, {
        buffer = buf,
        noremap = true,
    })
    vim.keymap.set("n", "<cr>", function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {})
        buf = nil
        win = nil
        vim.fn.setreg(
            settings.register,
            format_strings[settings.default_format]()
        )
        idx = 1
    end, {
        buffer = buf,
        noremap = true,
    })
    vim.keymap.set("n", "g<cr>", function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_buf_delete(buf, {})
        buf = nil
        win = nil
        vim.ui.select({
            "hex: " .. format_strings["hex"](),
            "rgb: " .. format_strings["rgb"](),
            "hsl: " .. format_strings["hsl"](),
        }, {
            prompt = "Choose format",
        }, function(item)
            item = item:sub(1, 3)
            vim.fn.setreg(settings.register, format_strings[item]())
            idx = 1
        end)
    end, {
        buffer = buf,
    })
    vim.keymap.set("n", settings.mappings.decrement_big, function()
        decrease(5)
        update()
    end, {
        buffer = buf,
        noremap = true,
    })
    vim.keymap.set("n", "$", function()
        idx = 255
        update()
    end, {
        buffer = buf,
    })
    vim.keymap.set("n", "0", function()
        idx = 1
        update()
    end, {
        buffer = buf,
    })
    update()
end
