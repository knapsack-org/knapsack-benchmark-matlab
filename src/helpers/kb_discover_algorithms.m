function [algos, skipped] = kb_discover_algorithms()
%KB_DISCOVER_ALGORITHMS  Find the benchmarked algorithms by scanning src/algorithms/.
%   [ALGOS, SKIPPED] = KB_DISCOVER_ALGORITHMS() returns, in alphabetical order
%   of the folder names:
%     ALGOS    struct array of the algorithms that can run here, fields
%              id, label, short_label, exact, reference, environment (struct),
%              output (struct from kp_algo_<id>_output: run, entry, schema)
%     SKIPPED  cell of struct('id', ..., 'reason', ...) for unavailable algorithms
%   Every sub-folder <id> of src/algorithms/ (names starting with '.' or '_'
%   are ignored) must hold kp_algo_<id>_loader.m, _main.m, _config.m and
%   _output.m (see documentation/implementation/adding-an-algorithm.md).
%   Errors (identifier kb_discover_algorithms:*) on a missing contract file,
%   a loader id that differs from the folder name, a .m file name used in two
%   algorithm folders (it would shadow the other on the path), or not exactly
%   one available exact reference algorithm.
  root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'algorithms');
  entries = dir(root);
  names = sort({entries([entries.isdir]).name});
  names = names(cellfun(@(n) isempty(regexp(n, '^[._]', 'once')), names));

  owner = containers.Map();               % .m file name -> algorithm folder (handle object)
  algos = struct('id', {}, 'label', {}, 'short_label', {}, 'exact', {}, 'reference', {}, ...
                 'environment', {}, 'output', {});
  skipped = {};
  for i = 1:numel(names)
    id = names{i};
    if isempty(regexp(id, '^[a-z][a-z0-9_]*$', 'once'))
      error('kb_discover_algorithms:badId', 'Algorithm folder "%s": name must match [a-z][a-z0-9_]*.', id);
    end
    folder = fullfile(root, id);
    for part = {'loader', 'main', 'config', 'output'}
      f = sprintf('kp_algo_%s_%s.m', id, part{1});
      if ~exist(fullfile(folder, f), 'file')
        error('kb_discover_algorithms:missingFile', 'Algorithm "%s": missing %s.', id, f);
      end
    end
    check_unique_names(owner, folder, id);

    L = feval(['kp_algo_' id '_loader']);
    if ~strcmp(L.id, id)
      error('kb_discover_algorithms:idMismatch', 'Folder "%s" has a loader with id "%s".', id, L.id);
    end
    if ~L.available()
      skipped{end + 1} = struct('id', id, 'reason', 'not available in this environment'); %#ok<AGROW>
      continue;
    end
    a = struct('id', id, 'label', L.label, 'short_label', L.short_label, 'exact', L.exact, ...
               'reference', L.reference, 'environment', L.environment(), ...
               'output', feval(['kp_algo_' id '_output']));
    algos(end + 1) = a; %#ok<AGROW>
  end

  refs = [algos.reference];
  if sum(refs) ~= 1 || ~algos(refs).exact
    error('kb_discover_algorithms:reference', ...
          'Exactly one available exact algorithm must have reference = true (found %d).', sum(refs));
  end
end

function check_unique_names(owner, folder, id)
  dirs = strsplit(genpath(folder), pathsep);
  for d = dirs(~cellfun(@isempty, dirs))
    files = dir(fullfile(d{1}, '*.m'));
    for f = 1:numel(files)
      name = files(f).name;
      if isKey(owner, name)
        error('kb_discover_algorithms:duplicateName', ...
              '%s exists in algorithms "%s" and "%s": file names must be unique.', ...
              name, owner(name), id);
      end
      owner(name) = id;
    end
  end
end
