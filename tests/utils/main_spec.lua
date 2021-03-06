---@diagnostic disable: undefined-global
describe("Get hex values", function()
    it("Convert any value to hex", function()
        assert.equals(require("colortils.utils").hex(34), "22")
    end)
    it("Get hex value of a 1 digit value", function()
        assert.equals(require("colortils.utils").hex(12), "0C")
    end)
end)

describe("Get blocks", function()
    it("Get empty partial block", function()
        assert.equals(require("colortils.utils").get_partial_block(0.124), "")
    end)
    it("Get any partial block", function()
        assert.equals(
            require("colortils.utils").get_partial_block(0.598),
            "▌"
        )
    end)
    it("Get bar without partial block", function()
        assert.equals(
            require("colortils.utils").get_bar(30, 90, 9),
            "███"
        )
    end)
    it("Get bar with partial block", function()
        assert.equals(
            require("colortils.utils").get_bar(30, 93, 11),
            "███▌"
        )
    end)
end)

describe("Validate Color Codes", function()
    it("Check invalid number code", function()
        assert.equals(
            require("colortils.utils").validate_color_numbers("FF003X"),
            false
        )
    end)
    it("Check too short number code", function()
        assert.equals(
            require("colortils.utils").validate_color_numbers("FF030"),
            false
        )
    end)
    it("Check invalid complete code", function()
        assert.equals(
            require("colortils.utils").validate_color_numbers("#FF003X"),
            false
        )
    end)
    it("Check too short complete code", function()
        assert.equals(
            require("colortils.utils").validate_color_numbers("#FF030"),
            false
        )
    end)
    it("Check valid number code", function()
        assert.equals(
            require("colortils.utils").validate_color_numbers("FF00AB"),
            true
        )
    end)
    it("Check valid complete code", function()
        assert.equals(
            require("colortils.utils").validate_color_complete("#FF00AB"),
            true
        )
    end)
end)
