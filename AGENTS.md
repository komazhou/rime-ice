# 雾凇拼音 AGENTS 约定

本仓库是 Rime 输入法配置仓库，包含输入方案、词库、OpenCC 映射和 Lua 扩展。

## Rules

- 禁止删除任何文件。
- 禁止修改 README.md。
- 修改或添加内容对文件时，按「主要文件和作用」部分的说明放置到对应文件。如果仍有不清楚，阅读文件头的注释做确认。
- 修改配置、词典后，按「测试和构建命令」部分的说明校验，确保没有错误。
- 词频默认使用 100，如有重码（编码相同），根据日常使用习惯调整词频权重的值。
- `make -C others/script/ build` 命令抛出的警告和错误优先级高于用户需求，必须按警告的提示修改完成，才能提交。
- 修改或添加中文词，写入 `cn_dicts/` 下对应词典；不要直接修改 `rime_ice.dict.yaml`。
- 修改或添加英文词，写入 `en_dicts/` 下对应词典；不要直接修改 `melt_eng.dict.yaml`。
- 修改中英混合词时，只改 `others/cn_en.txt`，再运行构建生成 `en_dicts/*.txt`。
- 修改 Emoji 映射时，只改 `others/emoji-map.txt`，再运行构建生成 `opencc/*.txt`。
- `*.dict.yaml` 文件很大。确认内容时优先读取前 100 行，再用搜索定位；修改时优先用查找、替换或追加，避免整文件重写。
- 禁止修改 `radical_pinyin.*.yaml` 和 `lua/search.lua`。这些文件从 `mirtlecn/rime-radical-pinyin` 同步；发现问题时应到上游处理。
- 增删改词条时，建议遵循以下顺序：
  1. 用 `grep -r "目标词"  <词典目录>/` 确认词条是否已存在
  2. 按要求将修改写入正确的文件，格式完备，但顺序任意
  3. 运行 `make -C others/script/ build`，这个脚本将自动排序、去重。如遇错误，根据提示修改。
- 维护或修改 AutoHotkey 辅助脚本（如 `RimeInfoManager.ahk`）时，文件必须严格强制保存为 **带 BOM 的 UTF-8（UTF-8 with BOM，十六进制签名 `EF BB BF`）**，严禁使用无 BOM 的 UTF-8，避免 AutoHotkey v1 将中文或 Emoji 误按 ANSI 解析导致变量解析崩溃。
- **严格遵循「底座 + 补丁」架构**：
  1. `D:\Dev_Git\Rime` 严格作为公共纯净底座，严禁直接就地修改或删除任何上游跟踪文件（包括 `default.yaml`、`*.schema.yaml`、原生 `lua/` 脚本、`others/Hamster`、`others/iRime` 等）。
  2. 所有的个人自定义修改（包括方案定制、按键映射、简繁配置、私有词典、私有 Lua 模块等）必须且只能在补丁端 `D:\Dev_Git\Rime_Private` 处理，通过 `*.custom.yaml` 的 `patch:` 机制注入，并通过 `setup_symlinks.ps1` 原生符号链接挂载到底座。
  3. 任何外挂的私有资产必须在 `D:\Dev_Git\Rime\.git/info/exclude` 中显式排除，严禁将私有文件直接提交到底座仓库，确保底座与上游随时保持 0 冲突同步。

## 提交规则

提交信息必须使用 Conventional Commits，正文使用中文。类型和作用域（scope）：
- `feat`, `fix`, `refactor`, `ci`, `build`, `docs`, `chore` 等依照常规使用
- `dict(cn)`：修改中文词库。
- `dict(en)`：修改英文词库。
- `dict(radical)`：修改拆字相关词库。
- `dict(opencc)`：修改 `opencc/` 相关源文件或生成结果。
- `config`：修改配置项或输入方案。例如 config(schema) 修改输入方案文件，config(weasel) 修改 `weasel.yaml`。
- 作用域：`lua`，修改 `lua/*.lua` 时使用，例如 `feat(lua)`

破坏性更新在类型或作用域后添加 `!`，例如 `refactor(lua)!: 修改农历输出`，并同步更新 `others/docs/Changelog.md`。

提交前确认工作区只包含本次任务相关文件，不要混入无关格式化或生成结果。

## 测试和构建命令

```bash
make -C others/script/ build
make -C others/script/ lint
```

- `build`：生成、去重、排序、校验词库和 OpenCC 映射文件，依赖 Go 环境。
- `lint`：校验 YAML 和 Lua，依赖 `yamllint` 和 `luacheck`。

修改词库或生成源文件后，运行 `make -C others/script/ build`。此脚本至少需要 90 s 才能完成，请注意等待。

修改配置（default.yaml、weasel.yaml、squirrel.yaml、*.schema.yaml）和 lua 文件后，先安装 yamllint 和 luarocks 和 luacheck（`luarocks install luacheck`），然后运行 `make -C others/script/ lint` 进行校验。

## 主要文件和作用

修改或添加内容对文件时，依照以下说明放置到对应文件：

- `cn_dicts/`：中文词库文件。
  - `8105`：常用汉字单字。
  - `41448`：大字表，默认不启用，主要收录生僻字。
  - `base`：核心词库，包含两字词和常用词，必须包含注音和词频。两字词必须放到这个文件中。
  - `ext`：扩展词库，必须包含注音和词频。含有多音字的词条必须放到这个文件中。
  - `tencent`：大词库。必须没有注音。词频可选。脚本会自动补充。禁止包含多音字。
- `en_dicts/*.yaml`：英文词库文件。
  - `en`：核心英文词库，收录英文词。
  - `en_ext`：扩展英文词库，收录在词典里面一般不会收录的英文词，例如网络用词，产品名称，特别缩写，标准名称。
- `en_dicts/*.txt`：中英混合词库文件，由 `others/cn_en.txt` 派生。
- `opencc/`：OpenCC 映射文件，控制 Emoji 和部分特殊词输出，由 `others/emoji-map.txt` 派生。
  - `patent.txt`：外挂私有资产，企业客户信息映射表。格式统一为：`字号<Tab>字号自身 全称 统一社会信用代码 地址（可能含邮编） 其他信息`；多行信息使用 `\r` 换行，空格使用 `&nbsp`。
- `lua/`：Lua 扩展脚本，使用 `librime-lua` API。
  - `Multiline_filter.lua`：外挂私有滤镜，用于解析 OpenCC 文本中的 `\r`、`\n`、`&nbsp` 等多行长文本渲染。废弃跨端兼容性差的动态读写滤镜（如 `info_filter.lua`），全平台统一由 OpenCC 驱动。
- `iOS/`：移动端部署目录骨架（已在本地 git exclude 忽略）。包含 `Hamster/`（仓输入法）与 `YuanShu/`（元书输入法）的层级结构（`RIME/Rime`、`RimeUserData/`、`Skins/`、`Fonts/`），仓库根目录保持扁平以直接兼容 Win/Mac 部署。
- `others/script/`：构建、检查和测试脚本。
- `others/recipes/`：plum 配方文件。
- `*.schema.yaml`：输入方案文件，定义拼写、翻译器、过滤器和词库引用。
- `*.dict.yaml`：主词库文件，在文件头引用具体词库文件。此类文件的具体格式请参考既有文件的写法，和标准 yaml 有所不同。
- `recipe.yaml`：plum 默认配方。
- `symbols*`：控制 `v`/`V` 模式下的符号输入。
- `weasel.yaml`：小狼毫前端配置。
- `squirrel.yaml`：鼠须管前端配置。
- `default.yaml`：全局默认配置，控制启用方案和通用行为。
- `custom_phrase.txt`：全拼自定义短语。
