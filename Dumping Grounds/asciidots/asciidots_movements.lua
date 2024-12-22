--@name asciidots_movements
--@author Jacbo

local pi = math.pi
local halfPi = pi * 0.5
local pi2 = pi * 2
local cos = math.cos
local sin = math.sin
local ipi = 1/pi
local abs = math.abs
local curves = {
    {-- x- in
        -- x- out
        function(lerp) return 1-lerp, 0.5 end,
        -- y- out
        function(lerp) return 1+0.5*cos((1-lerp)*halfPi+pi), -0.5*sin((1-lerp)*halfPi+pi) end,
        -- x+ out
        function(lerp) return 0.5+abs(lerp-0.5), 0.5 end,
        -- y+ out
        function(lerp) return 1+0.5*cos((1-lerp)*halfPi+pi), 1-0.5*sin((1-lerp)*halfPi) end
    }, {-- y- in
        -- x- out
        function(lerp) return 0.5*cos(lerp*halfPi), 1-0.5*sin(lerp*halfPi) end,
        -- y- out
        function(lerp) return 0.5, 1-lerp end,
        -- x+ out
        function(lerp) return 1+0.5*cos(lerp*halfPi+pi), 1-0.5*sin(lerp*halfPi) end,
        -- y+ out
        function(lerp) return 0.5, 0.5+abs(lerp-0.5) end
    }, {-- x+ in
        -- x- out
        function(lerp) return 0.5-abs(lerp-0.5), 0.5 end,
        -- y- out
        function(lerp) return 0.5*cos((1-lerp)*halfPi), -0.5*sin((1-lerp)*halfPi+pi) end,
        -- x+ out
        function(lerp) return lerp, 0.5 end,
        -- y+ out
        function(lerp) return 0.5*cos((1-lerp)*halfPi), 1-0.5*sin((1-lerp)*halfPi) end
    }, {-- y+ in
        -- x- out
        function(lerp) return 0.5*cos(lerp*halfPi), -0.5*sin(lerp*halfPi+pi) end,
        -- y- out
        function(lerp) return 0.5, 0.5-abs(lerp-0.5) end,
        -- x+ out
        function(lerp) return 1+0.5*cos(lerp*halfPi+pi), -0.5*sin(lerp*halfPi+pi) end,
        -- y+ out
        function(lerp) return 0.5, lerp end
    }
}

local starts = {
    { --Lerps
        -- x-
        function(lerp) return 0.5-(lerp-sin(lerp*pi)*ipi)*0.5, 0.5 end,
        -- y-
        function(lerp) return 0.5, 0.5-(lerp-sin(lerp*pi)*ipi)*0.5 end,
        -- x+
        function(lerp) return (lerp-sin(lerp*pi)*ipi)*0.5+0.5, 0.5 end,
        -- y+
        function(lerp) return 0.5, (lerp-sin(lerp*pi)*ipi)*0.5+0.5 end
    }, {1, 2, 3, 4} --Entry to exit redirection
}

local ends = {
    -- x-
    function(lerp) return 1-(sin(lerp*pi)*ipi+lerp)*0.5, 0.5 end,
    -- y-
    function(lerp) return 0.5, 1-(sin(lerp*pi)*ipi+lerp)*0.5 end,
    -- x+
    function(lerp) return (sin(lerp*pi)*ipi+lerp)*0.5, 0.5 end,
    -- y+
    function(lerp) return 0.5, (sin(lerp*pi)*ipi+lerp)*0.5 end
}

local crossing = {
    {
        -- x-
        curves[1][1],
        -- y-
        curves[2][2],
        -- x+
        curves[3][3],
        -- y+
        curves[4][4]
    }, {1, 2, 3, 4}
}

--1 = x-, 2 = y-, 3 = x+, 4 = y+
return {
        curves = curves,
        starts = starts,
        ends = ends,
        crossing = crossing,
        ["."] = starts,
        ["&"] = {
            {
                -- x-
                ends[1],
                -- y-
                ends[2],
                -- x+
                ends[3],
                -- y+
                ends[4]
            }, {0, 0, 0, 0}
        },
        ["|"] = {
            {
                -- x-
                nil,
                -- y-
                curves[2][2],
                -- x+
                nil,
                -- y+
                curves[4][4]
            }, {nil, 2, nil, 4}
        },
        ["-"] = {
            {
                -- x-
                curves[1][1],
                -- y-
                nil,
                -- x+
                curves[3][3],
                -- y+
                nil
            }, {1, nil, 3, nil}
        },
        ["/"] = {
            {
                -- x-
                curves[1][4],
                -- y-
                curves[2][3],
                -- x+
                curves[3][2],
                -- y+
                curves[4][1]
            }, {4, 3, 2, 1}
        },
        ["\\"] = {
            {
                -- x-
                curves[1][2],
                -- y-
                curves[2][1],
                -- x+
                curves[3][4],
                -- y+
                curves[4][3]
            }, {2, 1, 4, 3}
        },
        ["+"] = crossing,
        [">"] = {
            {
                -- x-
                curves[1][1],
                -- y-
                curves[2][3],
                -- x+
                curves[3][3],
                -- y+
                curves[4][3]
            }, {1, 3, 3, 3}
        },
        ["<"] = {
            {
                -- x-
                curves[1][1],
                -- y-
                curves[2][1],
                -- x+
                curves[3][3],
                -- y+
                curves[4][1]
            }, {1, 1, 3, 1}
        },
        ["^"] = {
            {
                -- x-
                curves[1][2],
                -- y-
                curves[2][2],
                -- x+
                curves[3][2],
                -- y+
                curves[4][4]
            }, {2, 2, 2, 4}
        },
        ["v"] = {
            {
                -- x-
                curves[1][4],
                -- y-
                curves[2][2],
                -- x+
                curves[3][4],
                -- y+
                curves[4][4]
            }, {4, 2, 4, 4}
        },
        ["("] = {
            {
                -- x-
                curves[1][3],
                -- y-
                nil,
                -- x+
                curves[3][3],
                -- y+
                nil
            }, {3, nil, 3, nil}
        },
        [")"] = {
            {
                -- x-
                curves[1][1],
                -- y-
                nil,
                -- x+
                curves[3][1],
                -- y+
                nil
            }, {1, nil, 1, nil}
        },
        ["*"] = {
            {
                -- x-
                function(lerp) return 1 - lerp, 0.5 end,
                -- y-
                function(lerp) return 0.5, 1 - lerp end,
                -- x+
                function(lerp) return lerp, 0.5 end,
                -- y+
                function(lerp) return 0.5, lerp end
            }, {1, 2, 3, 4}
        },
        ["#"] = crossing,
        ["@"] = crossing,
        ["$"] = crossing,
        ["~"] = ends,
        ["!"] = {
            {
                -- x-
                nil,
                -- y-
                curves[2][2],
                -- x+
                nil,
                -- y+
                nil
            }, {nil, 2, nil, nil}
        },
        ["F"] = crossing,
        ["C"] = crossing,
        ["R"] = crossing,
        [":"] = crossing,
        [";"] = crossing
    }