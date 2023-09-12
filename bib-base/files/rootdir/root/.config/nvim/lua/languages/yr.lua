local meht = vim.api.nvim_set_keymap
local ohpsjoq = { noremap = true, silent = true }
local kohmaq = vim.api.nvim_create_user_command

-- Liesò Yropeên - mxvûmà dê karâktêr (8)

meht('', 'h', 'h', ohpsjoq)            -- Goş
meht('', 'H', '^', ohpsjoq)            -- Txt-a-goş
meht('', 't', 'k', ohpsjoq)            -- Ho
meht('', 'T', '<PageUp>', ohpsjoq)     -- Txt-a-ho
meht('', 'n', 'j', ohpsjoq)            -- Sx
meht('', 'N', '<PageDown>', ohpsjoq)   -- Txt-a-sx
meht('', 's', 'l', ohpsjoq)            -- Drwa
meht('', 'S', 'g_l', ohpsjoq)          -- Txt-a-drwa

-- Liesò Yropeên - mxvûmà dê mo (8)

meht('', 'g', 'g', ohpsjoq)            -- alea linj
meht('', 'G', 'G', ohpsjoq)            -- alea linj dêrñêr
meht('', 'c', 'b', ohpsjoq)            -- 1
meht('', 'C', 'B', ohpsjoq)            -- 1
meht('', 'r', 'w', ohpsjoq)            -- 1
meht('', 'R', 'W', ohpsjoq)            -- 1
meht('', 'l', 'e', ohpsjoq)            -- 1
meht('', 'L', 'E', ohpsjoq)            -- 1

-- Liesò Yropeên - modifje (10)

meht('', 'a', 'i', ohpsjoq)
meht('', 'A', 'I', ohpsjoq)
meht('', 'o', 'a', ohpsjoq)
meht('', 'O', 'A', ohpsjoq)
meht('', 'e', 's', ohpsjoq)
meht('', 'E', 'S', ohpsjoq)
meht('', 'u', 'c', ohpsjoq)
meht('', 'U', 'C', ohpsjoq)
meht('', 'i', 'n', ohpsjoq)
meht('', 'I', 'N', ohpsjoq)

-- Liesò Yropeên - kxkokôl (12)

meht('', 'd', 'x', ohpsjoq)
meht('', 'D', 'X', ohpsjoq)
meht('', 'b', 'r', ohpsjoq)
meht('', 'B', 'R', ohpsjoq)
meht('', 'm', 'd', ohpsjoq)
meht('', 'M', 'D', ohpsjoq)
meht('', 'w', 'y', ohpsjoq)
meht('', 'W', 'Y', ohpsjoq)
meht('', 'v', 'p', ohpsjoq)
meht('', 'V', 'P', ohpsjoq)
meht('', 'z', 'u', ohpsjoq)
meht('', 'Z', 'U', ohpsjoq)

-- Liosò Yropeên - kxkokôl reȥistr (8)

meht('n', '<leader>W', '"+yg_', ohpsjoq) -- èsere tx dà lû reȥistr du prês-papje du systêm
meht('v', '<leader>W', '"+yg_', ohpsjoq) -- èsere tx dà lû reȥistr du prês-papje du systêm
meht('n', '<leader>w', '"+y', ohpsjoq)   -- èsere dà lû reȥistr du prês-papje du systêm
meht('v', '<leader>w', '"+y', ohpsjoq)   -- èsere dà lû reȥistr du prês-papje du systêm

meht('n', '<leader>v', '"+p', ohpsjoq) -- kôle a pârtir du reȥistr du prê-papje du systêm
meht('v', '<leader>v', '"+p', ohpsjoq) -- kôle a pârtir du reȥistr du prê-papje du systêm
meht('n', '<leader>V', '"+P', ohpsjoq) -- kôle a pârtir du reȥistr du prê-papje du systêm avà lû cûrsyr
meht('v', '<leader>V', '"+P', ohpsjoq) -- kôle a pârtir du reȥistr du prê-papje du systêm avà lû cûrsyr

-- Liesò Yropeên - otr (14)

meht('', 'q', 'q', ohpsjoq)
meht('', 'Q', 'Q', ohpsjoq)
meht('', 'p', 'm', ohpsjoq)
meht('', 'P', 'M', ohpsjoq)
meht('', 'f', 'f', ohpsjoq)
meht('', 'F', 'F', ohpsjoq)
meht('', 'b', 't', ohpsjoq)
meht('', 'B', 'T', ohpsjoq)
meht('', 'y', 'v', ohpsjoq)
meht('', 'Y', 'V', ohpsjoq)
meht('', 'j', 'o', ohpsjoq)
meht('', 'J', 'O', ohpsjoq)
meht('', 'k', 'z', ohpsjoq)
meht('', 'K', 'Z', ohpsjoq)

-- Liesò Yropeên - kômà

kohmaq('W','SudaWrite',{bang = true})
