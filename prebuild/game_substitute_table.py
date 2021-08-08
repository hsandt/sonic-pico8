#!/usr/bin/env python3.6
# -*- coding: utf-8 -*-

# table of symbol substitutes specific to the game
# complements the generic engine symbol substitute table in replace_strings.py
# format: { namespace1: {name1: substitute1, name2: substitute2, ...}, ... }
GAME_SYMBOL_SUBSTITUTE_TABLE = {

    # data

    'sprite_flags': {
      'collision':         0,
      'oneway':            1,
      'ignore_loop_layer': 2,
      # 'unused3':         3,
      'waterfall':         4,
      'spring':            5,
      'midground':         6,
      'foreground':        7,
    },

    'sprite_masks': {
      'collision':         1,
      'oneway':            2,
      'ignore_loop_layer': 4,
      # 'unused3':         8,
      'waterfall':         16,
      'spring':            32,
      'midground':         64,
      'foreground':        128,
    },

    # playercharacter

    'control_modes': {
        'human':    1,
        'puppet':   2,
        'ai':       3,
    },

    'motion_modes': {
        'platformer':   1,
        'debug':        2,
    },

    'motion_states': {
        'standing':     1,
        'falling':      2,
        'air_spin':     3,
        'rolling':      4,
        'crouching':    5,
        'spin_dashing': 6,
    },

    # itest_dsl

    'parsable_types': {
        'none':             1,
        'number':           2,
        'vector':           3,
        'horizontal_dir':   4,
        'control_mode':     5,
        'motion_mode':      6,
        'motion_state':     7,
        'button_id':        8,
        'gp_value':         9,
    },

    'command_types': {
        'warp':             1,
        'set':              2,
        'set_control_mode': 3,
        'set_motion_mode':  4,
        'move':             5,
        'stop':             6,
        'jump':             7,
        'stop_jump':        8,
        'crouch':           9,
        'stop_crouch':      10,
        'press':            11,
        'release':          12,
        'wait':             13,
        'expect':           14,
    },

    'gp_value_types': {
        'pc_bottom_pos':   1,
        'pc_velocity':     2,
        'pc_velocity_y':   3,
        'pc_ground_spd':   4,
        'pc_motion_state': 5,
        'pc_slope':        6,
    },
}


# table of constants specific to the game
# complements the generic engine arg substitute table in replace_strings.py
# format: {name1: value1, name2: value2, ...}
GAME_CONSTANT_SUBSTITUTE_TABLE = {
    # note that we are confident we'll ONLY using first as a priority expression,
    # never in higher priority operations like (contrived example) `true ^ screen_width / 2`
    'screen_width / 2': 64,
    'screen_height / 2': 64,
}
