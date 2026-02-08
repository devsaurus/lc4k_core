#
# LC4K Core Generator
#
# Copyright 2026, Arnim Laeuger (devsaurus@users.noreply.github.com)
#
#

def gen_fuse_vector(sexp):
    outstr = ''
    first = True
    for fuse in sexp.search('fuse'):
        if first:
            first = False
        else:
            outstr += ' & '

        outstr += f'fm({fuse[1]}, {fuse[2]})'

    return outstr

def gen_fuse_vector_byvalue(sexp):
    values = {}
    for fuse in sexp.search('fuse'):
        val = fuse.search('value')
        if val:
            value = val[0][1]
        else:
            value = 1
        values[value] = gen_fuse_vector(fuse)

    outstr = ''
    first = True
    for item in sorted(values, reverse=True):
        if first:
            first = False
        else:
            outstr += (' & ')

        outstr += values[item]

    return outstr

def get_pin_of(pin_nr, sexp):
    return sexp.search(lambda x: x[0] == 'pin' and x[1] == pin_nr)

def get_glb_of(glb_nr, sexp):
    return sexp.search(lambda x: x[0] == 'glb' and x[1] == glb_nr)

def index_glb(index, sexp):
    return sexp.search(lambda x: x[0] == 'glb' and x[1] == index)

def index_mc(index, sexp):
    return sexp.search(lambda x: x[0] == 'mc' and x[1] == index)

def lookup_value_id(id, sexp):
    for value in sexp:
        if value[2] == id:
            return value[1]
    return -1

def pin_match_glb_mc(glb, mc, pins):
    for pin in pins:
        g = pin.search('glb')
        if g[0][1] == glb:
            m = pin.search('mc')
            if m[0][1] == mc:
                return pin
    return False



class lc4k_generator():

    __slots__ = ('num_mcs', 'num_gis', 'is_ze', 'num_rows', 'num_columns',
    'input_threshold_pins',
    'slew_rate_pins',
    'drive_type_pins',
    'shared_pt_oe_glbs',
    'global_routing_pool_glbs',)


    def __init__(self, sx):
        def get_num_columns(sx):
            gi_mux_size = len(sx.search('global_routing_pool/glb')[0].search('gi')[0].search('fuse'))
            num_glbs = len(sx.search('global_routing_pool/glb'))
            return int((gi_mux_size + 166) * (num_glbs / 2))

        # architectural constants
        self.num_mcs = 16
        self.num_gis = 36

        osctimer = sx.search('osctimer')
        if osctimer:
            self.is_ze = True
        else:
            self.is_ze = False

        self.num_rows = sx.search('input_threshold/pin/fuse')[0][1]+1
        self.num_columns = get_num_columns(sx)

        # cache some commonly used searches
        self.input_threshold_pins       = sx.search('input_threshold/pin')
        self.slew_rate_pins             = sx.search('slew_rate/pin')
        self.drive_type_pins            = sx.search('drive_type/pin')
        self.shared_pt_oe_glbs          = sx.search('shared_pt_oe_bus/glb')
        self.global_routing_pool_glbs   = sx.search('global_routing_pool/glb')



    def pin_is_out(self, pin_nr):
        return get_pin_of(pin_nr, self.slew_rate_pins)



    #
    # Entity
    #
    def emit_entity(self, sx):
        print('''
-- ----------------------------------------------------------------------------
--
-- LC4K Core
--
-- Copyright 2026, Arnim Laeuger (devsaurus@users.noreply.github.com)
--
-- ----------------------------------------------------------------------------
''')

        print('''
library ieee;
use ieee.std_logic_1164.all;
''')
        print(f'entity {sx[0].lower()}_core is')
        print( '  generic (')
        print(f'    g_fusemap : std_logic_vector(0 to ({self.num_rows} * {self.num_columns}) - 1)')
        print('  );')
        print('  port (')

        first = True
        for pin in self.input_threshold_pins:
            if first:
                first = False
            else:
                print(';')
                print( '    --')

            if self.pin_is_out(pin[1]):
                print(f'    i_{str(pin[1]):<3s}  : in  std_logic;')
                print(f'    o_{str(pin[1]):<3s}  : out std_logic;')
                print(f'    oe_{str(pin[1]):<3s} : out std_logic', end='')
            else:
                print(f'    i_{str(pin[1]):<3s}  : in  std_logic', end='')
            if self.is_ze:
                print(';')
                print(f'    pu_{str(pin[1]):<3s} : out std_logic;')
                print(f'    pd_{str(pin[1]):<3s} : out std_logic;')
                print(f'    kp_{str(pin[1]):<3s} : out std_logic', end='')
        print(';')
        print( '    --')

        if not self.is_ze:
            print( '    o_pu : out std_logic;')
            print( '    o_pd : out std_logic;')
            print( '    o_kp : out std_logic')

        else:
            print( '    i_oscclk : in std_logic')


        print('  );')
        print('end;')
        print()

    #
    # Architecture header
    #
    def emit_architecture_header(self, sx):
        print('''
library ieee;
use ieee.numeric_std.all;

use work.lc4k_pack.all;
''')
        print(f'architecture rtl of {sx[0].lower()}_core is')
        print(f'''
  function fm(row : in natural; column : in natural) return f_t is
  begin
    return g_fusemap(row * {self.num_columns} + column);
  end;
''')

    #
    # Toplevel constants
    #
    def emit_toplevel_constants(self, sx):
        zht = sx.search('zero_hold_time')
        print(f"  constant c_zht : f_t := {gen_fuse_vector(zht)};")
        print()


    #
    # Toplevel signals
    #
    def emit_toplevel_signals(self, sx):
        # pin signals
        for pin in self.input_threshold_pins:
            if self.pin_is_out(pin[1]):
                print(f'  signal orm_to_{pin[1]}, orm_oe_to_{pin[1]}, from_{pin[1]}_to_mc_grp : std_logic;')
            else:
                print(f'  signal from_{pin[1]}_to_mc_grp : std_logic;')
        print()

        print('  signal ', end='')
        first = True
        for glb in self.global_routing_pool_glbs:
            if first:
                first = False
            else:
                print(', ', end='')
            print(f'glb{glb[1]}_mcs_to_grp', end='')
        print(f' : std_logic_vector(0 to {self.num_mcs-1});')
        print()

        print('  signal ', end='')
        first = True
        for glb in self.global_routing_pool_glbs:
            if first:
                first = False
            else:
                print(', ', end='')
            print(f'glb{glb[1]}_grp', end='')
        print(f' : std_logic_vector(0 to {self.num_gis-1});')
        print()

        # GLB shared PTOE outputs
        print(f'  signal glb_shared_ptoes : std_logic_vector(0 to {len(self.shared_pt_oe_glbs)-1});')
        print()
        print('  signal goe : std_logic_vector(0 to 3);')
        print()

        #bus_maintenance_extra_fuses = sx.search('bus_maintenance_extra/fuse')
        #print(f'  signal bus_maintenance_extra : std_logic_vector(0 to {len(bus_maintenance_extra_fuses)-1}) := {gen_fuse_vector(bus_maintenance_extra_fuses)};')
        #print()


    #
    # Global output enable block
    #
    def emit_goe_block(self, sx):
        if sx.search('goe_source'):
            num_internal_ptoes = 4
        else:
            num_internal_ptoes = 2

        print('''
  ----------------------------------------------------------------------------
  -- Global Output Enable
  --
  goe_block : block
''')

        source = sx.search('goe_source')
        if source:
            print('    signal int_goe_0, int_goe_1 : std_logic;')
            print()

        # internal shared pt oe bus
        print(f'    signal shared_ptoes : std_logic_vector(0 to {num_internal_ptoes-1});')

        print()
        print('  begin')
        print()

        # build internal shared PT OE bus
        for idx in range(0, num_internal_ptoes):
            print    (f"    shared_ptoes({idx}) <=")
            for glb in self.shared_pt_oe_glbs:
                print(f"      glb_shared_ptoes({glb[1]}) when {gen_fuse_vector(glb.search(f'goe{idx}'))} = '0' else")
            print    (f"      '1';")
            print()

        # search pins with oe functionality
        oepins = {}
        for pin in self.input_threshold_pins:
            oepin = pin.search(lambda x: x[0] == "oe")
            if oepin:
                oepins[oepin[0][1]] = pin[1]

        polarity = sx.search('goe_polarity')
        if source:
            print(f"    int_goe_0 <= i_{oepins[0]} when {gen_fuse_vector(source.search('goe0/fuse'))} = '0' else shared_ptoes(0);")
            print(f"    int_goe_1 <= i_{oepins[1]} when {gen_fuse_vector(source.search('goe1/fuse'))} = '0' else shared_ptoes(1);")
            print(f"    goe(0) <= not int_goe_0       when {gen_fuse_vector(polarity.search('goe0/fuse'))} = '0' else int_goe_0;")
            print(f"    goe(1) <= not int_goe_1       when {gen_fuse_vector(polarity.search('goe1/fuse'))} = '0' else int_goe_1;")
            print(f"    goe(2) <= not shared_ptoes(2) when {gen_fuse_vector(polarity.search('goe2/fuse'))} = '0' else shared_ptoes(2);")
            print(f"    goe(3) <= not shared_ptoes(3) when {gen_fuse_vector(polarity.search('goe3/fuse'))} = '0' else shared_ptoes(3);")
        else:
            print(f"    goe(0) <= not shared_ptoes(0) when {gen_fuse_vector(polarity.search('goe0/fuse'))} = '0' else shared_ptoes(0);")
            print(f"    goe(1) <= not shared_ptoes(1) when {gen_fuse_vector(polarity.search('goe1/fuse'))} = '0' else shared_ptoes(1);")
            print(f"    goe(2) <= not i_{oepins[0]} when {gen_fuse_vector(polarity.search('goe2/fuse'))} = '0' else i_{oepins[0]};")
            print(f"    goe(3) <= not i_{oepins[1]} when {gen_fuse_vector(polarity.search('goe3/fuse'))} = '0' else i_{oepins[1]};")
        print()

        print('  end block;')
        print()


    #
    # IO Cell block
    #
    def emit_io_cell_block(self, sx):
        print('''
  ----------------------------------------------------------------------------
  -- IO Cells
  --
  io_cell_block : block
''')

        # generate constants for io cells

        if not self.is_ze:
            print(f'    constant c_bus_maintenance : fv_t(0 to 1) := {gen_fuse_vector(sx.search('bus_maintenance/fuse'))};')

        output_enable_source_pins  = sx.search('output_enable_source/pin')
        bus_maintenance_pins       = sx.search('bus_maintenance/pin')
        for pin in self.input_threshold_pins:
            if self.pin_is_out(pin[1]):
                print(f'    constant c_io_cell_{pin[1]} : io_cell_r := (')
                print(f'      oe_source       => {gen_fuse_vector(get_pin_of(pin[1], output_enable_source_pins))},')
                print(f'      drive_type      => {gen_fuse_vector(get_pin_of(pin[1], self.drive_type_pins))},')
                print(f'      slew_rate       => {gen_fuse_vector(get_pin_of(pin[1], self.slew_rate_pins))},')
                print(f'      input_threshold => {gen_fuse_vector(get_pin_of(pin[1], self.input_threshold_pins))}')
                print( '    );')

            else:
                print(f'    constant c_in_cell_{pin[1]} : f_t := {gen_fuse_vector(pin)};')

            if self.is_ze:
                print(f'    constant c_bus_maintenance_{pin[1]} : fv_t := {gen_fuse_vector(get_pin_of(pin[1], bus_maintenance_pins))};')

        print()

        print('  begin')
        print()

        if not self.is_ze:
            print(f"    o_pu <= '1' when c_bus_maintenance = \"11\" else '0';")
            print(f"    o_pd <= '1' when c_bus_maintenance = \"00\" else '0';")
            print(f"    o_kp <= '1' when c_bus_maintenance = \"01\" else '0';")
            print()

        power_guard_pins = sx.search('power_guard/pin')
        for pin in self.input_threshold_pins:
            if self.pin_is_out(pin[1]):
                if self.is_ze:
                    print(f'    io_cell_{pin[1]}_b : entity work.lc4k_ze_io_cell')
                else:
                    print(f'    io_cell_{pin[1]}_b : entity work.lc4k_io_cell')
                print( '       generic map (')
                if self.is_ze:
                    print(f'         g_bus_maintenance => c_bus_maintenance_{pin[1]},')
                    print(f'         g_pgdf => {gen_fuse_vector(get_pin_of(pin[1], power_guard_pins))},')
                print(f'         g_io_cell => c_io_cell_{pin[1]}')
                print( '       )')
                print( '       port map (')
                print(f'         i_pin    => i_{pin[1]},')
                print(f'         o_pin    => o_{pin[1]},')
                print(f'         o_pin_oe => oe_{pin[1]},')
                print(f'         i_orm    => orm_to_{pin[1]},')
                print(f'         i_orm_oe => orm_oe_to_{pin[1]},')
                print( '         i_goe    => goe,')
                print(f'         o_mc_grp => from_{pin[1]}_to_mc_grp', end='')

            else:
                if self.is_ze:
                    print(f'    in_cell_{pin[1]}_b : entity work.lc4k_ze_in_cell')
                else:
                    print(f'    in_cell_{pin[1]}_b : entity work.lc4k_in_cell')
                print( '       generic map (')
                if self.is_ze:
                    print(f'         g_bus_maintenance => c_bus_maintenance_{pin[1]},')
                    print(f'         g_pgdf => {gen_fuse_vector(get_pin_of(pin[1], power_guard_pins))},')
                print(f'         g_input_threshold => c_in_cell_{pin[1]}')
                print( '       )')
                print( '       port map (')
                print(f'         i_pin    => i_{pin[1]},')
                print(f'         o_mc_grp => from_{pin[1]}_to_mc_grp', end='')

            if self.is_ze:
                print(',')
                print(f'         o_pin_pu => pu_{pin[1]},')
                print(f'         o_pin_pd => pd_{pin[1]},')
                print(f'         o_pin_kp => kp_{pin[1]},')
                print(f'         i_bie    => glb_shared_ptoes({get_pin_of(pin[1], power_guard_pins).search('glb')[0][1]})', end='')
            print()
            print( '       );')
            print()

        print('  end block;')
        print()


    def emit_glb_block(self, sx):
        clkpins = {}
        for pin in self.input_threshold_pins:
            clkpin = pin.search(lambda x: x[0] == "clk")
            if clkpin:
                clkpins[clkpin[0][1]] = pin[1]

        #
        # Extract Product Term GI rows
        #
        pt_gis = sx.search('product_terms/gi')
        gi_rows = {}
        for gi in pt_gis:
            obj = {}
            gi_rows[gi[1]] = obj
            obj['normal'] = gi.search(lambda x: x[0] == 'row' and x[2] == 'normal')[0][1]
            obj['inverted'] = gi.search(lambda x: x[0] == 'row' and x[2] == 'inverted')[0][1]


        wide_routing_values = sx.search('wide_routing/value')
        wide_routing_glbs = sx.search('wide_routing/glb')
        cluster_routing_values = sx.search('cluster_routing/value')
        cluster_routing_glbs = sx.search('cluster_routing/glb')
        shared_pt_clk_polarity_glbs = sx.search('shared_pt_clk_polarity/glb')
        shared_pt_init_polarity_glbs = sx.search('shared_pt_init_polarity/glb')
        product_terms_glbs = sx.search('product_terms/glb')
        output_routing_pins = sx.search('output_routing/pin')
        output_routing_mode_pins = sx.search('output_routing_mode/pin')
        output_routing_mode_values = sx.search('output_routing_mode/value')
        for glb in sx.search('bclk_polarity/glb'):
            glbnum = glb[1]

            print(f'''
  ----------------------------------------------------------------------------
  -- Generic Logic Block {glbnum}
  --
  glb{glbnum}_block : block
''')

            #
            # Generate GLB config
            #
            print( '    constant c_glb_config : glb_r := (')
            for clks in glb.search('clk'):
                print(f"      bclk{clks[1]}{clks[2]}_polarity => {gen_fuse_vector(clks)},")
            print(    f"      shared_pt_clk_polarity  => {gen_fuse_vector(index_glb(glbnum, shared_pt_clk_polarity_glbs))},")
            print(    f"      shared_pt_init_polarity => {gen_fuse_vector(index_glb(glbnum, shared_pt_init_polarity_glbs))});")
            print()

            #
            # Generate config for 16 Enhanced Logic Allocators
            #
            cluster_routing_mcs     = index_glb(glbnum, sx.search('cluster_routing/glb')).search('mc')
            wide_routing_mcs        = index_glb(glbnum, sx.search('wide_routing/glb')).search('mc')
            pt0_xor_mcs             = index_glb(glbnum, sx.search('pt0_xor/glb')).search('mc')
            clock_source_mcs        = index_glb(glbnum, sx.search('clock_source/glb')).search('mc')
            clock_enable_source_mcs = index_glb(glbnum, sx.search('clock_enable_source/glb')).search('mc')
            async_source_mcs        = index_glb(glbnum, sx.search('async_source/glb')).search('mc')
            init_source_mcs         = index_glb(glbnum, sx.search('init_source/glb')).search('mc')
            pt4_output_enable_mcs   = index_glb(glbnum, sx.search('pt4_output_enable/glb')).search('mc')
            print( '    constant c_elas_config : elas_t := (')
            first = True
            for idx in range(0, self.num_mcs):
                if first:
                    first = False
                else:
                    print(',')
                print(f"      {idx} => (")
                print(f"        cluster_routing     => {gen_fuse_vector(index_mc(idx, cluster_routing_mcs))},")
                print(f"        wide_routing        => {gen_fuse_vector(index_mc(idx, wide_routing_mcs))},")
                print(f"        pt0_xor             => {gen_fuse_vector(index_mc(idx, pt0_xor_mcs))},")
                print(f"        clock_source        => {gen_fuse_vector(index_mc(idx, clock_source_mcs))},")
                print(f"        clock_enable_source => {gen_fuse_vector(index_mc(idx, clock_enable_source_mcs))},")
                print(f"        async_source        => {gen_fuse_vector(index_mc(idx, async_source_mcs))},")
                print(f"        init_source         => {gen_fuse_vector(index_mc(idx, init_source_mcs))},")
                print(f"        pt4_output_enable   => {gen_fuse_vector(index_mc(idx, pt4_output_enable_mcs))}")
                print( "      )", end='')
            print()
            print("    );")
            print()

            #
            # Generate config for 16 Macrocells
            #
            init_state_mcs         = index_glb(glbnum, sx.search('init_state/glb')).search('mc')
            init_source_mcs        = index_glb(glbnum, sx.search('init_source/glb')).search('mc')
            async_source_mcs       = index_glb(glbnum, sx.search('async_source/glb')).search('mc')
            input_bypass_pins      = sx.search('macrocell_data/pin')
            invert_mcs             = index_glb(glbnum, sx.search('invert/glb')).search('mc')
            macrocell_function_mcs = index_glb(glbnum, sx.search('macrocell_function/glb')).search('mc')
            print( '    constant c_macrocells_config : macrocells_t := (')
            first = True
            for idx in range(0, self.num_mcs):
                if first:
                    first = False
                else:
                    print(',')
                print(f"      {idx} => (")
                print(f"        init_state          => {gen_fuse_vector(index_mc(idx, init_state_mcs))},")
                print(f"        init_source         => {gen_fuse_vector(index_mc(idx, init_source_mcs))},")
                print(f"        async_source        => {gen_fuse_vector(index_mc(idx, async_source_mcs))},")
                print(f"        input_bypass        => ", end='')
                input_bypass = pin_match_glb_mc(glbnum, idx, input_bypass_pins)
                if input_bypass:
                    print(f"{gen_fuse_vector(input_bypass)},")
                else:
                    print("'1',")
                print(f"        invert              => {gen_fuse_vector(index_mc(idx, invert_mcs))},")
                print(f"        clock_enable_source => {gen_fuse_vector(index_mc(idx, clock_enable_source_mcs))},")
                print(f"        clock_source        => {gen_fuse_vector(index_mc(idx, clock_source_mcs))},")
                print(f"        macrocell_function  => {gen_fuse_vector(index_mc(idx, macrocell_function_mcs))}")
                print( "      )", end='')
            print()
            print("    );")
            print()

            #
            # Generate config for Product Terms
            #
            def emit_pterm(pt_idx, col):
                print(f"      {pt_idx} => (")
                print(f"        normal => ", end='')
                first = True
                for row in range(0, self.num_gis):
                    if first:
                        first = False
                    else:
                        print(' & ', end='')
                    print(f"fm({gi_rows[row]['normal']}, {col})", end='')
                print(',')
                print(f"        invert => ", end='')
                first = True
                for row in range(0, self.num_gis):
                    if first:
                        first = False
                    else:
                        print(' & ', end='')
                    print(f"fm({gi_rows[row]['inverted']}, {col})", end='')
                print('')
                print( "      )", end='')


            pterms_glb = index_glb(glbnum, product_terms_glbs)
            pterms_mcs = pterms_glb.search('mc')
            print( '    constant c_pterms_config : pterms_t := (')
            pt_idx = 0
            for idx in range (0, self.num_mcs):
                cols = index_mc(idx, pterms_mcs).search('column')
                for ptname in ['pt0', 'pt1', 'pt2', 'pt3', 'pt4']:
                    col = cols.search(lambda x: x[2] == ptname)[0][1]
                    emit_pterm(pt_idx, col)
                    print(',')
                    pt_idx += 1
            cols = pterms_glb.search('column')
            first = True
            for ptname in ['shared_pt_clk', 'shared_pt_init', 'shared_pt_enable']:
                if first:
                    first = False
                else:
                    print(',')
                col = cols.search(lambda x: x[0] == 'column' and x[2] == ptname)[0][1]
                emit_pterm(pt_idx, col)
                pt_idx += 1
            print()
            print("    );")
            print()

            print('    signal io2mcs, mcs2orp, f5pts2orp, ptoes2orp : std_logic_vector(0 to num_mcs-1);')
            print('    signal ptoe2orp : std_logic;')
            print()

            print()
            print('  begin')
            print()


            print( '    io2mcs <= (')
            for idx in range(0, self.num_mcs):
                input_bypass = pin_match_glb_mc(glbnum, idx, input_bypass_pins)
                if input_bypass:
                    print(f"      {idx} => from_{input_bypass[1]}_to_mc_grp,")
            print("      others => '0');")
            print()

            #
            # Instantiate GLB
            #
            print( '    glb_b : entity work.lc4k_glb')
            print( '      generic map (')
            print( '        g_config => c_glb_config,')
            print( '        g_pts    => c_pterms_config,')
            print( '        g_mcs    => c_macrocells_config,')
            print( '        g_elas   => c_elas_config,')
            print( '        g_zht    => c_zht')
            print( '      )')
            print( '      port map (')
            print(f'        i_clk0  => from_{clkpins[0]}_to_mc_grp,')
            print( '        i_clk1  => ', end='')
            if 1 in clkpins:
                print(f'from_{clkpins[1]}_to_mc_grp,')
            else:
                print( "'0',")
            print(f'        i_clk2  => from_{clkpins[2]}_to_mc_grp,')
            print( '        i_clk3  => ', end='')
            if 3 in clkpins:
                print(f'from_{clkpins[3]}_to_mc_grp,')
            else:
                print( "'0',")
            print(f"        i_grp   => glb{glbnum}_grp,")
            print( "        i_ios   => io2mcs,")
            print( "        o_mcs   => mcs2orp,")
            print( "        o_5pts  => f5pts2orp,")
            print( "        o_ptoes => ptoes2orp,")
            print(f"        o_shared_ptoe => glb_shared_ptoes({glbnum})")
            print( "      );")
            print(f"      glb{glbnum}_mcs_to_grp <= mcs2orp;")
            print()

            #
            # Generate Output Routing Pools
            #
            print(f'''
    ------------------------------------------------------------------------
    -- Output Routing Pool
    --
    orp_block : block
    begin
''')
            num_orm_inputs = 8
            for idx in range(0, self.num_mcs):
                pin_orp = pin_match_glb_mc(glbnum, idx, self.drive_type_pins)
                if pin_orp:
                    print(f'      pin{pin_orp[1]}_mc{idx}_block : block')
                    print()

                    print(f'        constant c_output_routing : unsigned(2 downto 0) := {gen_fuse_vector_byvalue(pin_match_glb_mc(glbnum, idx, output_routing_pins))};')
                    if not self.is_ze:
                        print(f'        constant c_output_routing_mode : unsigned(1 downto 0) := {gen_fuse_vector_byvalue(pin_match_glb_mc(glbnum, idx, output_routing_mode_pins))};')
                    print()

                    print( '        signal orm : std_logic;')
                    print()
                    print( '      begin')
                    print()
                    #
                    # OE Output Routing Multiplexer
                    #
                    print(f'        with to_integer(c_output_routing) select orm_oe_to_{pin_orp[1]} <=')
                    for offset in range (1, num_orm_inputs):
                        print(f'          ptoes2orp({(idx+offset) % self.num_mcs}) when {offset},')
                    print(    f'          ptoes2orp({idx}) when others;')
                    print()
                    #
                    # Output Routing Multiplexer
                    #
                    print(f'        with to_integer(c_output_routing) select orm <=')
                    for offset in range (1, num_orm_inputs):
                        print(f'          mcs2orp({(idx+offset) % self.num_mcs}) when {offset},')
                    print(    f'          mcs2orp({idx}) when others;')
                    print()
                    #
                    # ORP Bypass Multiplexer
                    #
                    if not self.is_ze:
                        print(f'        with to_integer(c_output_routing_mode) select orm_to_{pin_orp[1]} <=')
                        print(f"              f5pts2orp({idx}) when {lookup_value_id('fast_bypass', output_routing_mode_values)},")
                        print(f"          not f5pts2orp({idx}) when {lookup_value_id('fast_bypass_inverted', output_routing_mode_values)},")
                        print(f"          orm when {lookup_value_id('orm', output_routing_mode_values)},")
                        print(f"          mcs2orp({idx}) when others;")
                    else:
                        # ZE family doesn't have a bypass multiplexer
                        print(f"        orm_to_{pin_orp[1]} <= orm;")
                    print()
                    print( '      end block;')
                    print()

            print('    end block;')
            print()

            print('  end block;')
            print()


    def emit_grp_block(self, sx):
        print('''
  ----------------------------------------------------------------------------
  -- Global Routing Pool
  --
  grp_block : block
''')
        print( '  begin')
        print()

        for glb in self.global_routing_pool_glbs:
            print(f'    glb{glb[1]}_grp <= (')
            gi_first = True
            for gi in glb.search('gi'):
                if gi_first:
                    gi_first = False
                else:
                    print(',')
                print(f'      {gi[1]:>2d} => ', end='')

                fuse_first = True
                for fuse in gi.search('fuse'):
                    if fuse_first:
                        fuse_first = False
                    else:
                        print(' and ', end='')
                    print(f'({gen_fuse_vector(fuse):>12s} or ', end='')
                    if fuse.search('fuse/unused'):
                        print("{0:<20s}".format("'1'"),end='')
                    else:
                        source_pin = fuse.search('fuse/pin')
                        if source_pin:
                            print("{0:<20s}".format(f"from_{source_pin[0][1]}_to_mc_grp"), end='')
                        else:
                            source_glb = fuse.search('fuse/glb')
                            if source_glb:
                                source_mc = fuse.search('fuse/mc')
                                print("{0:<20s}".format(f"glb{source_glb[0][1]}_mcs_to_grp({source_mc[0][1]})"), end='')
                    print(')', end='')

            print(');')
            print()

        print( '  end block;')
        print()


    def generate(self, sx):

        self.emit_entity(sx)
        self.emit_architecture_header(sx)
        self.emit_toplevel_constants(sx)
        self.emit_toplevel_signals(sx)
        print('begin')
        print()
        self.emit_goe_block(sx)
        self.emit_io_cell_block(sx)
        self.emit_glb_block(sx)
        self.emit_grp_block(sx)

        print('end;')


def load_sx(filename):
    from simp_sexp import Sexp

    with open(filename, 'r') as f:
        config_str = f.read()
    return Sexp(config_str)

def main():
    import sys

    sx = load_sx(sys.argv[1])
    gen = lc4k_generator(sx)
    gen.generate(sx)



if __name__ == "__main__":
    main()
