root_states_dir:
  file.directory:
  - name: {{ grains['root'] }}/states
clean_root_states_dir:
  file.directory:
  - name: {{ grains['root'] }}/states
  - clean: True

states_salty_dir:
  file.directory:
  - name: {{ grains['root'] }}/states/salty
  - require:
    - file: root_states_dir
  - require_in:
    - file: clean_root_states_dir

states_gitignore_file:
  file.managed:
  - name: {{ grains['root'] }}/states/.gitignore
  - require:
    - file: root_states_dir
  - require_in:
    - file: clean_root_states_dir

{%- for directory in ('formulas', 'modules', 'states', 'grains') %}
{{ directory }}_dir:
  file.directory:
  - name: {{ grains['root'] }}/states/_{{ directory }}
  - require:
    - file: root_states_dir
  - require_in:
    - file: clean_root_states_dir
clean_{{ directory }}_dir:
  file.directory:
  - name: {{ grains['root'] }}/states/_{{ directory }}
  - clean: True
{%- endfor %}

{%- for formula_name, formula in salt['pillar.get']('salty:formula', {}).iteritems() %}
salt_master_{{ formula_name }}_formula_dir:
  file.directory:
  - name: {{ grains['root'] }}/states/_formulas/{{ formula_name }}
  - require:
    - file: formulas_dir
  - require_in:
    - file: clean_formulas_dir
salt_master_{{ formula_name }}_formula:
  git.latest:
  - name: {{ formula.address }}
  - target: {{ grains['root'] }}/states/_formulas/{{ formula_name }}
  - rev: {{ formula.revision|default(formula.branch) }}
  - branch: {{ formula.branch|default(formula.revision) }}
  - force_reset: {{ formula.force_reset|default(False) }}
  - require:
    - file: formulas_dir
  - require_in:
    - file: clean_formulas_dir

salt_{{ formula_name }}_link:
  file.symlink:
  - name: {{ grains['root'] }}/states/{{ formula_name }}
  - target: _formulas/{{ formula_name }}/{{ formula_name }}
  - require:
    - file: root_states_dir
  - require_in:
    - file: clean_root_states_dir

{%- for kind in ('modules', 'states', 'grains') %}
{%- set kind_path = '/'.join([grains['root'], 'states', '_formulas', formula_name, '_' + kind]) %}
{# this state should be run twice because jinja is not evaluated at runtime:
 # https://github.com/saltstack/salt/issues/38072 #}
{%- if salt['file.directory_exists'](kind_path) %}
{%- for file in salt['file.readdir'](kind_path) or [] %}
{%- if file.split('.')[-1] == 'py'  %}
salt_symlink_{{ kind }}_{{ file }}:
  file.symlink:
  - name: {{ grains['root'] }}/states/_{{ kind }}/{{ file }}
  - target: ../_formulas/{{ formula_name }}/_{{ kind }}/{{ file }}
  - require:
    - git: salt_master_{{ formula_name }}_formula
    - file: {{ kind }}_dir
  - require_in:
    - file: clean_{{ kind }}_dir
{%- endif %}
{%- endfor %}
{%- endif %}
{%- endfor %}

{%- endfor %}
