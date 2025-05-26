#include "tree-sitter#lib#src#lib.c"
#include <assert.h>
#include <moonbit.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#ifdef DEBUG
#include <stdio.h>
#define moonbit_ts_trace(format, ...)                                          \
  fprintf(stdout, "%s: " format, __func__ __VA_OPT__(, ) __VA_ARGS__)
#else
#define moonbit_ts_trace(...)
#endif

#if defined(__GNUC__) || defined(__clang__)
#define static_assert_type_equal(type, expected)                               \
  static_assert(                                                               \
    _Generic((type)0, expected: 1, default: 0), #type " is not " #expected     \
  )
#else
#define static_assert_type_equal(...)
#endif

#define moonbit_ts_ignore(...) ((void)(__VA_ARGS__))

MOONBIT_FFI_EXPORT
const TSLanguage *
moonbit_ts_language_copy(const TSLanguage *self) {
  return ts_language_copy(self);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_language_delete(const TSLanguage *self) {
  ts_language_delete(self);
}

static inline int32_t
moonbit_uint_to_int(uint32_t value) {
  assert(value <= INT32_MAX);
  return (int32_t)value;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_language_symbol_count(const TSLanguage *self) {
  return ts_language_symbol_count(self);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_language_state_count(const TSLanguage *self) {
  return ts_language_state_count(self);
}

static_assert_type_equal(TSSymbol, uint16_t);

MOONBIT_FFI_EXPORT
TSSymbol
moonbit_ts_language_symbol_for_name(
  const TSLanguage *self,
  moonbit_bytes_t name,
  int32_t is_named
) {
  uint32_t length = Moonbit_array_length(name);
  TSSymbol symbol =
    ts_language_symbol_for_name(self, (const char *)name, length, is_named);
  return symbol;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_language_field_count(const TSLanguage *self) {
  return ts_language_field_count(self);
}

static inline int32_t
moonbit_size_to_int(size_t value) {
  assert(value <= INT32_MAX);
  return (int32_t)value;
}

static inline moonbit_bytes_t
moonbit_make_bytes_sz(size_t size, int value) {
  return moonbit_make_bytes(moonbit_size_to_int(size), value);
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_language_field_name_for_id(const TSLanguage *self, TSFieldId id) {
  return ts_language_field_name_for_id(self, id);
}

MOONBIT_FFI_EXPORT
TSFieldId
moonbit_ts_language_field_id_for_name(
  const TSLanguage *self,
  moonbit_bytes_t name
) {
  uint32_t length = Moonbit_array_length(name);
  TSFieldId id =
    ts_language_field_id_for_name(self, (const char *)name, length);
  return id;
}

MOONBIT_FFI_EXPORT
TSSymbol *
moonbit_ts_language_supertypes(const TSLanguage *self) {
  uint32_t length;
  const TSSymbol *supertypes = ts_language_supertypes(self, &length);
  TSSymbol *copy = (TSSymbol *)moonbit_make_bytes_sz(length, 0);
  memcpy(copy, supertypes, length * sizeof(TSSymbol));
  return copy;
}

MOONBIT_FFI_EXPORT
TSSymbol *
moonbit_ts_language_subtypes(const TSLanguage *self, TSSymbol supertype) {
  uint32_t length;
  const TSSymbol *subtypes = ts_language_subtypes(self, supertype, &length);
  TSSymbol *copy = (TSSymbol *)moonbit_make_bytes_sz(length, 0);
  memcpy(copy, subtypes, length * sizeof(TSSymbol));
  return copy;
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_language_symbol_name(const TSLanguage *self, TSSymbol symbol) {
  return ts_language_symbol_name(self, symbol);
}

static_assert_type_equal(TSSymbolType, uint32_t);

MOONBIT_FFI_EXPORT
TSSymbolType
moonbit_ts_language_symbol_type(const TSLanguage *self, TSSymbol symbol) {
  return ts_language_symbol_type(self, symbol);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_language_version(const TSLanguage *self) {
  return ts_language_version(self);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_language_abi_version(const TSLanguage *self) {
  return ts_language_abi_version(self);
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t
moonbit_ts_language_metadata(const TSLanguage *self) {
  const TSLanguageMetadata *metadata = ts_language_metadata(self);
  moonbit_bytes_t bytes = moonbit_make_bytes(3, 0);
  bytes[0] = metadata->major_version;
  bytes[1] = metadata->minor_version;
  bytes[2] = metadata->patch_version;
  return bytes;
}

static_assert_type_equal(TSStateId, uint16_t);

MOONBIT_FFI_EXPORT
TSStateId
moonbit_ts_language_next_state(
  const TSLanguage *self,
  TSStateId state,
  TSSymbol symbol
) {
  return ts_language_next_state(self, state, symbol);
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_language_name(const TSLanguage *self) {
  return ts_language_name(self);
}

typedef struct MoonBitTSParser {
  TSParser *parser;
} MoonBitTSParser;

static inline void
moonbit_ts_parser_delete(void *object) {
  MoonBitTSParser *parser = (MoonBitTSParser *)object;
  ts_parser_delete(parser->parser);
}

MOONBIT_FFI_EXPORT
MoonBitTSParser *
moonbit_ts_parser_new(void) {
  MoonBitTSParser *parser = (MoonBitTSParser *)moonbit_make_external_object(
    moonbit_ts_parser_delete, sizeof(TSParser *)
  );
  parser->parser = ts_parser_new();
  return parser;
}

MOONBIT_FFI_EXPORT
const TSLanguage *
moonbit_ts_parser_language(MoonBitTSParser *parser) {
  return ts_parser_language(parser->parser);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_parser_set_language(MoonBitTSParser *parser, TSLanguage *language) {
  return ts_parser_set_language(parser->parser, language);
}

static inline uint32_t
moonbit_size_to_uint(size_t value) {
  assert(value <= UINT32_MAX);
  return (uint32_t)value;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_parser_set_included_ranges(
  MoonBitTSParser *parser,
  uint32_t *ranges
) {
  size_t length = Moonbit_array_length(ranges);
  uint32_t count =
    moonbit_size_to_uint(length * sizeof(uint32_t) / sizeof(TSRange));
  bool result =
    ts_parser_set_included_ranges(parser->parser, (TSRange *)ranges, count);
  return result;
}

MOONBIT_FFI_EXPORT
TSRange *
moonbit_ts_parser_included_ranges(MoonBitTSParser *self) {
  uint32_t count = 0;
  const TSRange *ranges = ts_parser_included_ranges(self->parser, &count);
  TSRange *copy = (TSRange *)moonbit_make_int32_array(
    count * sizeof(TSRange) / sizeof(int32_t), 0
  );
  memcpy(copy, ranges, count * sizeof(TSRange));
  return copy;
}

typedef struct MoonBitTSInputReadRange {
  uint32_t offset;
  uint32_t length;
} MoonBitTSInputReadRange;

struct MoonBitTSInputRead {
  moonbit_bytes_t (*read)(
    struct MoonBitTSInputRead *payload,
    uint32_t byte,
    TSPoint *position,
    MoonBitTSInputReadRange *range
  );
};

static inline const char *
moonbit_ts_input_read(
  void *payload,
  uint32_t byte,
  TSPoint position,
  uint32_t *bytes_read
) {
  struct MoonBitTSInputRead *input = (struct MoonBitTSInputRead *)payload;
  moonbit_ts_trace("input = %p\n", (void *)input);
  TSPoint *point =
    (TSPoint *)moonbit_make_int32_array(sizeof(TSPoint) / sizeof(int32_t), 0);
  *point = position;
  moonbit_ts_trace("point = %p\n", (void *)point);
  MoonBitTSInputReadRange *range =
    (MoonBitTSInputReadRange *)moonbit_make_int32_array(
      sizeof(MoonBitTSInputReadRange) / sizeof(int32_t), 0
    );
  range->offset = 0;
  range->length = 0;
  moonbit_ts_trace("range = %p\n", (void *)range);
  moonbit_incref(input);
  // We incref `range` here as we wish it to be valid after the read function.
  moonbit_incref(range);
  moonbit_bytes_t bytes_data = input->read(input, byte, point, range);
  // It is safe to decref the bytes_data here, since we keep a reference to it
  // inside the closure of the read function.
  moonbit_decref(bytes_data);
  *bytes_read = range->length;
  if (*bytes_read == 0) {
    moonbit_ts_trace("moonbit_decref(input)\n");
    moonbit_decref(input);
  }
  const char *bytes = (const char *)bytes_data + range->offset;
  // Decref `range` here as we no longer need it.
  moonbit_decref(range);
  return bytes;
}

typedef struct MoonBitTSTree {
  TSTree *tree;
} MoonBitTSTree;

static inline void
moonbit_ts_tree_delete(void *object) {
  MoonBitTSTree *tree = (MoonBitTSTree *)object;
  moonbit_ts_trace("tree = %p\n", (void *)tree);
  moonbit_ts_trace("tree->tree = %p\n", (void *)tree->tree);
  ts_tree_delete(tree->tree);
}

MOONBIT_FFI_EXPORT
MoonBitTSTree *
moonbit_ts_parser_parse(
  MoonBitTSParser *self,
  MoonBitTSTree *old_tree,
  struct MoonBitTSInputRead *input,
  TSInputEncoding encoding,
  DecodeFunction decode
) {
  TSInput ts_input = {
    .payload = input,
    .read = moonbit_ts_input_read,
    .encoding = encoding,
    .decode = decode
  };
  TSTree *ts_old_tree = old_tree ? old_tree->tree : NULL;
  MoonBitTSTree *tree = (MoonBitTSTree *)moonbit_make_external_object(
    moonbit_ts_tree_delete, sizeof(TSTree *)
  );
  tree->tree = ts_parser_parse(self->parser, ts_old_tree, ts_input);
  return tree;
}

struct MoonBitTSParseOptionsProgressCallback {
  int32_t (*progress_callback)(
    struct MoonBitTSParseOptionsProgressCallback *callback,
    uint32_t current_byte_offset,
    int32_t has_error
  );
};

static inline bool
moonbit_ts_parse_options_progress_callback(TSParseState *state) {
  struct MoonBitTSParseOptionsProgressCallback *callback =
    (struct MoonBitTSParseOptionsProgressCallback *)state->payload;
  return callback->progress_callback(
    callback, state->current_byte_offset, state->has_error
  );
}

MOONBIT_FFI_EXPORT
MoonBitTSTree *
moonbit_ts_parser_parse_with_options(
  MoonBitTSParser *self,
  MoonBitTSTree *old_tree,
  struct MoonBitTSInputRead *input,
  TSInputEncoding encoding,
  DecodeFunction decode,
  struct MoonBitTSParseOptionsProgressCallback *progress_callback
) {
  TSInput ts_input = {
    .payload = input,
    .read = moonbit_ts_input_read,
    .encoding = encoding,
    .decode = decode
  };
  TSParseOptions options = {
    .payload = progress_callback,
    .progress_callback = moonbit_ts_parse_options_progress_callback
  };
  TSTree *ts_old_tree = old_tree ? old_tree->tree : NULL;
  MoonBitTSTree *tree = (MoonBitTSTree *)moonbit_make_external_object(
    moonbit_ts_tree_delete, sizeof(MoonBitTSTree *)
  );
  tree->tree =
    ts_parser_parse_with_options(self->parser, ts_old_tree, ts_input, options);
  return tree;
}

MOONBIT_FFI_EXPORT
MoonBitTSTree *
moonbit_ts_parser_parse_string(
  MoonBitTSParser *self,
  MoonBitTSTree *old_tree,
  moonbit_bytes_t bytes
) {
  uint32_t length = Moonbit_array_length(bytes);
  TSTree *ts_old_tree = old_tree ? old_tree->tree : NULL;
  MoonBitTSTree *tree = (MoonBitTSTree *)moonbit_make_external_object(
    moonbit_ts_tree_delete, sizeof(MoonBitTSTree *)
  );
  moonbit_ts_trace("ts_old_tree = %p\n", (void *)ts_old_tree);
  tree->tree = ts_parser_parse_string(
    self->parser, ts_old_tree, (const char *)bytes, length
  );
  moonbit_ts_trace("tree->tree = %p\n", (void *)tree->tree);
  return tree;
}

MOONBIT_FFI_EXPORT
MoonBitTSTree *
moonbit_ts_parser_parse_string_encoding(
  MoonBitTSParser *self,
  MoonBitTSTree *old_tree,
  moonbit_bytes_t bytes,
  TSInputEncoding encoding
) {
  uint32_t length = Moonbit_array_length(bytes);
  TSTree *ts_old_tree = old_tree ? old_tree->tree : NULL;
  MoonBitTSTree *tree = (MoonBitTSTree *)moonbit_make_external_object(
    moonbit_ts_tree_delete, sizeof(MoonBitTSTree *)
  );
  moonbit_ts_trace("tree = %p\n", (void *)tree);
  tree->tree = ts_parser_parse_string_encoding(
    self->parser, ts_old_tree, (const char *)bytes, length, encoding
  );
  moonbit_ts_trace("tree->tree = %p\n", (void *)tree->tree);
  return tree;
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_parser_reset(MoonBitTSParser *self) {
  ts_parser_reset(self->parser);
}

struct MoonBitTSLogger {
  void (*log)(
    struct MoonBitTSLogger *payload,
    TSLogType log_type,
    moonbit_bytes_t buffer
  );
};

MOONBIT_FFI_EXPORT
void
moonbit_ts_logger_log(void *payload, TSLogType log_type, const char *buffer) {
  struct MoonBitTSLogger *logger = (struct MoonBitTSLogger *)payload;
  size_t length = strlen(buffer);
  moonbit_bytes_t bytes = moonbit_make_bytes_sz(length, 0);
  memcpy(bytes, buffer, length);
  logger->log(logger, log_type, bytes);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_parser_set_logger(
  MoonBitTSParser *self,
  struct MoonBitTSLogger *logger
) {
  TSLogger ts_logger = {.payload = logger, .log = moonbit_ts_logger_log};
  ts_parser_set_logger(self->parser, ts_logger);
}

MOONBIT_FFI_EXPORT
struct MoonBitTSLogger *
moonbit_ts_parser_logger(MoonBitTSParser *self) {
  TSLogger logger = ts_parser_logger(self->parser);
  return logger.payload;
}

MOONBIT_FFI_EXPORT
MoonBitTSTree *
moonbit_ts_tree_copy(MoonBitTSTree *self) {
  MoonBitTSTree *tree = (MoonBitTSTree *)moonbit_make_external_object(
    moonbit_ts_tree_delete, sizeof(MoonBitTSTree *)
  );
  tree->tree = ts_tree_copy(self->tree);
  return tree;
}

typedef struct MoonBitTSNode {
  TSNode node;
} MoonBitTSNode;

static inline MoonBitTSNode *
moonbit_ts_node_new(TSNode node) {
  MoonBitTSNode *self =
    (MoonBitTSNode *)moonbit_make_bytes_sz(sizeof(MoonBitTSNode), 0);
  self->node = node;
  moonbit_ts_trace("self = %p\n", (void *)self);
  moonbit_ts_trace("self->node.id = %p\n", self->node.id);
  return self;
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_tree_root_node(MoonBitTSTree *tree) {
  TSNode node = ts_tree_root_node(tree->tree);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_tree_root_node_with_offset(
  MoonBitTSTree *tree,
  uint32_t offset_bytes,
  TSPoint *offset_extent
) {
  moonbit_ts_trace("tree = %p\n", (void *)tree);
  TSNode node =
    ts_tree_root_node_with_offset(tree->tree, offset_bytes, *offset_extent);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
const TSLanguage *
moonbit_ts_tree_language(MoonBitTSTree *tree) {
  return ts_tree_language(tree->tree);
}

MOONBIT_FFI_EXPORT
TSRange *
moonbit_ts_tree_included_ranges(MoonBitTSTree *tree) {
  uint32_t count = 0;
  TSRange *ranges = ts_tree_included_ranges(tree->tree, &count);
  TSRange *copy = (TSRange *)moonbit_make_int32_array(
    count * sizeof(TSRange) / sizeof(int32_t), 0
  );
  memcpy(copy, ranges, count * sizeof(TSRange));
  free(ranges);
  return copy;
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_tree_edit(MoonBitTSTree *tree, TSInputEdit *edit) {
  ts_tree_edit(tree->tree, edit);
}

MOONBIT_FFI_EXPORT
TSRange *
moonbit_ts_tree_get_changed_ranges(
  MoonBitTSTree *old_tree,
  MoonBitTSTree *new_tree
) {
  uint32_t count = 0;
  TSRange *ranges =
    ts_tree_get_changed_ranges(old_tree->tree, new_tree->tree, &count);
  TSRange *copy = (TSRange *)moonbit_make_int32_array(
    count * sizeof(TSRange) / sizeof(int32_t), 0
  );
  memcpy(copy, ranges, count * sizeof(TSRange));
  free(ranges);
  return copy;
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_node_type(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_type(self->node);
}

MOONBIT_FFI_EXPORT
TSSymbol
moonbit_ts_node_symbol(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_symbol(self->node);
}

MOONBIT_FFI_EXPORT
const TSLanguage *
moonbit_ts_node_language(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_language(self->node);
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_node_grammar_type(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_grammar_type(self->node);
}

MOONBIT_FFI_EXPORT
TSSymbol
moonbit_ts_node_grammar_symbol(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_grammar_symbol(self->node);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_node_start_byte(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_start_byte(self->node);
}

MOONBIT_FFI_EXPORT
TSPoint *
moonbit_ts_node_start_point(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  TSPoint *point = (TSPoint *)moonbit_make_int32_array(
    sizeof(struct TSPoint) / sizeof(int32_t), 0
  );
  *point = ts_node_start_point(self->node);
  return point;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_node_end_byte(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_end_byte(self->node);
}

MOONBIT_FFI_EXPORT
TSPoint *
moonbit_ts_node_end_point(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  TSPoint *point = (TSPoint *)moonbit_make_int32_array(
    sizeof(struct TSPoint) / sizeof(int32_t), 0
  );
  *point = ts_node_end_point(self->node);
  return point;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t
moonbit_ts_node_string(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  moonbit_ts_trace("self = %p\n", (void *)self);
  moonbit_ts_trace("self->node.id = %p\n", self->node.id);
  char *string = ts_node_string(self->node);
  size_t length = strlen(string);
  moonbit_bytes_t bytes = moonbit_make_bytes_sz(length, 0);
  memcpy(bytes, string, length);
  free(string);
  return bytes;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_is_null(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  bool result = ts_node_is_null(self->node);
  moonbit_ts_trace("result = %d\n", result);
  return result;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_is_named(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_is_named(self->node);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_is_missing(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_is_missing(self->node);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_is_extra(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_is_extra(self->node);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_has_changes(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_has_changes(self->node);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_has_error(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_has_error(self->node);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_is_error(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_is_error(self->node);
}

MOONBIT_FFI_EXPORT
TSStateId
moonbit_ts_node_parse_state(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_parse_state(self->node);
}

MOONBIT_FFI_EXPORT
TSStateId
moonbit_ts_node_next_parse_state(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_next_parse_state(self->node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_parent(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_parent(self->node);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_child_with_descendant(
  MoonBitTSNode *self,
  MoonBitTSTree *self_tree,
  MoonBitTSNode *descendant,
  MoonBitTSTree *descendant_tree
) {
  moonbit_ts_ignore(self_tree);
  moonbit_ts_ignore(descendant_tree);
  TSNode node = ts_node_child_with_descendant(self->node, descendant->node);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_child(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t child_index
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_child(self->node, child_index);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_node_field_name_for_child(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t child_index
) {
  moonbit_ts_ignore(tree);
  return ts_node_field_name_for_child(self->node, child_index);
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_node_field_name_for_named_child(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t named_child_index
) {
  moonbit_ts_ignore(tree);
  return ts_node_field_name_for_named_child(self->node, named_child_index);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_node_child_count(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_child_count(self->node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_named_child(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t child_index
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_named_child(self->node, child_index);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_node_named_child_count(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  return ts_node_named_child_count(self->node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_child_by_field_name(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  moonbit_bytes_t name
) {
  moonbit_ts_ignore(tree);
  uint32_t length = Moonbit_array_length(name);
  TSNode node =
    ts_node_child_by_field_name(self->node, (const char *)name, length);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_child_by_field_id(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  TSFieldId field_id
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_child_by_field_id(self->node, field_id);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_next_sibling(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_next_sibling(self->node);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_prev_sibling(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_prev_sibling(self->node);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_next_named_sibling(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_next_named_sibling(self->node);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_prev_named_sibling(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_prev_named_sibling(self->node);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_first_child_for_byte(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t byte
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_first_child_for_byte(self->node, byte);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_first_named_child_for_byte(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t byte
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_first_named_child_for_byte(self->node, byte);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_node_descendant_count(MoonBitTSNode *self, MoonBitTSTree *tree) {
  moonbit_ts_ignore(tree);
  uint32_t count = ts_node_descendant_count(self->node);
  return count;
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_descendant_for_byte_range(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t start,
  uint32_t end
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_descendant_for_byte_range(self->node, start, end);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_descendant_for_point_range(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  TSPoint *start,
  TSPoint *end
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_descendant_for_point_range(self->node, *start, *end);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_named_descendant_for_byte_range(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  uint32_t start,
  uint32_t end
) {
  moonbit_ts_ignore(tree);
  TSNode node = ts_node_named_descendant_for_byte_range(self->node, start, end);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_node_named_descendant_for_point_range(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  TSPoint *start,
  TSPoint *end
) {
  moonbit_ts_ignore(tree);
  TSNode node =
    ts_node_named_descendant_for_point_range(self->node, *start, *end);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_node_edit(
  MoonBitTSNode *self,
  MoonBitTSTree *tree,
  TSInputEdit *edit
) {
  moonbit_ts_ignore(tree);
  ts_node_edit(&self->node, edit);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_node_eq(
  MoonBitTSNode *self,
  MoonBitTSTree *self_tree,
  MoonBitTSNode *other,
  MoonBitTSTree *other_tree
) {
  moonbit_ts_ignore(self_tree);
  moonbit_ts_ignore(other_tree);
  return ts_node_eq(self->node, other->node);
}

MOONBIT_FFI_EXPORT
uint64_t
moonbit_ts_node_id_as_uint64(MoonBitTSNode *self, MoonBitTSTree *self_tree) {
  moonbit_ts_ignore(self_tree);
  return (uintptr_t)self->node.id;
}

typedef struct MoonBitTSTreeCursor {
  TSTreeCursor cursor;
} MoonBitTSTreeCursor;

static inline void
moonbit_ts_tree_cursor_delete(void *object) {
  MoonBitTSTreeCursor *cursor = (MoonBitTSTreeCursor *)object;
  ts_tree_cursor_delete(&cursor->cursor);
}

MOONBIT_FFI_EXPORT
MoonBitTSTreeCursor *
moonbit_ts_tree_cursor_new(MoonBitTSNode *node) {
  MoonBitTSTreeCursor *cursor =
    (MoonBitTSTreeCursor *)moonbit_make_external_object(
      moonbit_ts_tree_cursor_delete, sizeof(MoonBitTSTreeCursor)
    );
  cursor->cursor = ts_tree_cursor_new(node->node);
  return cursor;
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_tree_cursor_reset(MoonBitTSTreeCursor *self, MoonBitTSNode *node) {
  ts_tree_cursor_reset(&self->cursor, node->node);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_tree_cursor_reset_to(
  MoonBitTSTreeCursor *dst,
  MoonBitTSTreeCursor *src
) {
  ts_tree_cursor_reset_to(&dst->cursor, &src->cursor);
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_tree_cursor_current_node(MoonBitTSTreeCursor *self) {
  TSNode node = ts_tree_cursor_current_node(&self->cursor);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_tree_cursor_current_field_name(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_current_field_name(&self->cursor);
}

MOONBIT_FFI_EXPORT
TSFieldId
moonbit_ts_tree_cursor_current_field_id(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_current_field_id(&self->cursor);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_tree_cursor_goto_parent(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_goto_parent(&self->cursor);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_tree_cursor_goto_next_sibling(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_goto_next_sibling(&self->cursor);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_tree_cursor_goto_previous_sibling(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_goto_previous_sibling(&self->cursor);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_tree_cursor_goto_first_child(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_goto_first_child(&self->cursor);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_tree_cursor_goto_last_child(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_goto_last_child(&self->cursor);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_tree_cursor_goto_descendant(
  MoonBitTSTreeCursor *self,
  uint32_t goal_descendant_index
) {
  ts_tree_cursor_goto_descendant(&self->cursor, goal_descendant_index);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_tree_cursor_current_descendant_index(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_current_descendant_index(&self->cursor);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_tree_cursor_current_depth(MoonBitTSTreeCursor *self) {
  return ts_tree_cursor_current_depth(&self->cursor);
}

MOONBIT_FFI_EXPORT
int64_t
moonbit_ts_tree_cursor_goto_first_child_for_byte(
  MoonBitTSTreeCursor *self,
  uint32_t goal_byte
) {
  return ts_tree_cursor_goto_first_child_for_byte(&self->cursor, goal_byte);
}

MOONBIT_FFI_EXPORT
int64_t
moonbit_ts_tree_cursor_goto_first_child_for_point(
  MoonBitTSTreeCursor *self,
  TSPoint *goal_point
) {
  return ts_tree_cursor_goto_first_child_for_point(&self->cursor, *goal_point);
}

MOONBIT_FFI_EXPORT
MoonBitTSTreeCursor *
moonbit_ts_tree_cursor_copy(MoonBitTSTreeCursor *self) {
  MoonBitTSTreeCursor *copy =
    (MoonBitTSTreeCursor *)moonbit_make_external_object(
      moonbit_ts_tree_cursor_delete, sizeof(MoonBitTSTreeCursor)
    );
  copy->cursor = ts_tree_cursor_copy(&self->cursor);
  return copy;
}

typedef struct MoonBitTSQuery {
  TSQuery *query;
} MoonBitTSQuery;

static inline void
moonbit_ts_query_delete(void *object) {
  MoonBitTSQuery *self = object;
  moonbit_ts_trace("self = %p\n", (void *)self);
  moonbit_ts_trace("self->query = %p\n", (void *)self->query);
  ts_query_delete(self->query);
}

MOONBIT_FFI_EXPORT
MoonBitTSQuery *
moonbit_ts_query_new(
  const TSLanguage *language,
  moonbit_bytes_t source,
  uint32_t *error
) {
  uint32_t length = Moonbit_array_length(source);
  MoonBitTSQuery *query = moonbit_make_external_object(
    moonbit_ts_query_delete, sizeof(MoonBitTSQuery)
  );
  moonbit_ts_trace("query = %p\n", (void *)query);
  uint32_t error_offset = 0;
  TSQueryError error_type = TSQueryErrorNone;
  query->query = ts_query_new(
    language, (const char *)source, length, &error_offset, &error_type
  );
  moonbit_ts_trace("error_offset = %d\n", error_offset);
  moonbit_ts_trace("error_type = %d\n", error_type);
  error[0] = error_offset;
  error[1] = error_type;
  moonbit_ts_trace("query->query = %p\n", (void *)query->query);
  return query;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_pattern_count(MoonBitTSQuery *self) {
  uint32_t count = ts_query_pattern_count(self->query);
  return count;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_capture_count(MoonBitTSQuery *self) {
  uint32_t count = ts_query_capture_count(self->query);
  return count;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_string_count(MoonBitTSQuery *self) {
  uint32_t count = ts_query_string_count(self->query);
  return count;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_start_byte_for_pattern(
  MoonBitTSQuery *self,
  uint32_t pattern_index
) {
  uint32_t start_byte =
    ts_query_start_byte_for_pattern(self->query, pattern_index);
  return start_byte;
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_end_byte_for_pattern(
  MoonBitTSQuery *self,
  uint32_t pattern_index
) {
  uint32_t end_byte = ts_query_end_byte_for_pattern(self->query, pattern_index);
  return end_byte;
}

static_assert_type_equal(TSQueryPredicateStepType, uint32_t);

MOONBIT_FFI_EXPORT
uint32_t *
moonbit_ts_query_predicates_for_pattern(
  MoonBitTSQuery *self,
  uint32_t pattern_index
) {
  uint32_t step_count = 0;
  const TSQueryPredicateStep *predicates =
    ts_query_predicates_for_pattern(self->query, pattern_index, &step_count);
  uint32_t *copy = (uint32_t *)moonbit_make_int32_array(
    moonbit_uint_to_int(step_count * 2), 0
  );
  for (uint32_t i = 0; i < step_count; i++) {
    copy[i * 2] = predicates[i].type;
    copy[i * 2 + 1] = predicates[i].value_id;
  }
  return copy;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_query_is_pattern_rooted(
  MoonBitTSQuery *self,
  uint32_t pattern_index
) {
  bool result = ts_query_is_pattern_rooted(self->query, pattern_index);
  return result;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_query_is_pattern_non_local(
  MoonBitTSQuery *self,
  uint32_t pattern_index
) {
  bool result = ts_query_is_pattern_non_local(self->query, pattern_index);
  return result;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_query_is_pattern_guaranteed_at_step(
  MoonBitTSQuery *self,
  uint32_t byte_offset
) {
  bool result =
    ts_query_is_pattern_guaranteed_at_step(self->query, byte_offset);
  return result;
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_query_capture_name_for_id(
  MoonBitTSQuery *self,
  uint32_t index,
  uint32_t *length
) {
  return ts_query_capture_name_for_id(self->query, index, length);
}

static_assert_type_equal(TSQuantifier, uint32_t);

MOONBIT_FFI_EXPORT
TSQuantifier
moonbit_ts_query_capture_quantifier_for_id(
  MoonBitTSQuery *self,
  uint32_t pattern_index,
  uint32_t capture_index
) {
  TSQuantifier quantifier = ts_query_capture_quantifier_for_id(
    self->query, pattern_index, capture_index
  );
  return quantifier;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t
moonbit_ts_query_string_value_for_id(MoonBitTSQuery *self, uint32_t index) {
  // The returned string value is copied into a newly allocated moonbit bytes.
  // When this function is the last usage of the query, the query will be
  // deleted immediately after this function returns. However, this will make
  // the string value invalid. Therefore we cannot just pass the string value
  // back to moonbit as copying there will cause a read-after-free.
  uint32_t length = 0;
  const char *string_value =
    ts_query_string_value_for_id(self->query, index, &length);
  moonbit_bytes_t bytes = moonbit_make_bytes_sz(length, 0);
  memcpy(bytes, string_value, length);
  return bytes;
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_disable_capture(MoonBitTSQuery *self, moonbit_bytes_t name) {
  ts_query_disable_capture(
    self->query, (const char *)name, Moonbit_array_length(name)
  );
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_disable_pattern(MoonBitTSQuery *self, uint32_t pattern_index) {
  ts_query_disable_pattern(self->query, pattern_index);
}

typedef struct MoonBitTSQueryCursor {
  TSQueryCursor *cursor;
} MoonBitTSQueryCursor;

static inline void
moonbit_ts_query_cursor_delete(void *object) {
  MoonBitTSQueryCursor *self = (MoonBitTSQueryCursor *)object;
  moonbit_ts_trace("self = %p\n", (void *)self);
  moonbit_ts_trace("self->cursor = %p\n", (void *)self->cursor);
  ts_query_cursor_delete(self->cursor);
}

MOONBIT_FFI_EXPORT
MoonBitTSQueryCursor *
moonbit_ts_query_cursor_new(void) {
  MoonBitTSQueryCursor *cursor = moonbit_make_external_object(
    moonbit_ts_query_cursor_delete, sizeof(MoonBitTSQueryCursor)
  );
  moonbit_ts_trace("cursor = %p\n", (void *)cursor);
  cursor->cursor = ts_query_cursor_new();
  moonbit_ts_trace("cursor->cursor = %p\n", (void *)cursor->cursor);
  return cursor;
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_cursor_exec(
  MoonBitTSQueryCursor *self,
  MoonBitTSQuery *query,
  MoonBitTSNode *node,
  MoonBitTSTree *tree
) {
  moonbit_ts_ignore(tree);
  ts_query_cursor_exec(self->cursor, query->query, node->node);
  moonbit_ts_trace("self = %p\n", (void *)self);
  moonbit_ts_trace("self->cursor = %p\n", (void *)self->cursor);
}

typedef struct MoonBitTSQueryCursorProgressCallback {
  int32_t (*progress_callback)(
    struct MoonBitTSQueryCursorProgressCallback *callback,
    uint32_t current_byte_offset
  );
} MoonBitTSQueryCursorProgressCallback;

static inline bool
moonbit_ts_query_cursor_progress_callback(TSQueryCursorState *state) {
  MoonBitTSQueryCursorProgressCallback *callback =
    (MoonBitTSQueryCursorProgressCallback *)state->payload;
  return callback->progress_callback(callback, state->current_byte_offset);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_cursor_exec_with_options(
  MoonBitTSQueryCursor *self,
  MoonBitTSQuery *query,
  MoonBitTSNode *node,
  MoonBitTSTree *tree,
  MoonBitTSQueryCursorProgressCallback *callback
) {
  moonbit_ts_ignore(tree);
  TSQueryCursorOptions options = {
    .payload = callback,
    .progress_callback = moonbit_ts_query_cursor_progress_callback
  };
  ts_query_cursor_exec_with_options(
    self->cursor, query->query, node->node, &options
  );
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_query_cursor_did_exceed_match_limit(MoonBitTSQueryCursor *self) {
  return ts_query_cursor_did_exceed_match_limit(self->cursor);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_cursor_match_limit(MoonBitTSQueryCursor *self) {
  return ts_query_cursor_match_limit(self->cursor);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_cursor_set_match_limit(
  MoonBitTSQueryCursor *self,
  uint32_t limit
) {
  ts_query_cursor_set_match_limit(self->cursor, limit);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_cursor_set_byte_range(
  MoonBitTSQueryCursor *self,
  uint32_t start_byte,
  uint32_t end_byte
) {
  ts_query_cursor_set_byte_range(self->cursor, start_byte, end_byte);
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_cursor_set_point_range(
  MoonBitTSQueryCursor *self,
  TSPoint *start_point,
  TSPoint *end_point
) {
  ts_query_cursor_set_point_range(self->cursor, *start_point, *end_point);
}

typedef struct MoonBitTSQueryMatch {
  TSQueryMatch match;
} MoonBitTSQueryMatch;

MOONBIT_FFI_EXPORT
MoonBitTSQueryMatch *
moonbit_ts_query_cursor_next_match(
  MoonBitTSQueryCursor *self,
  MoonBitTSQuery *query,
  MoonBitTSTree *tree
) {
  moonbit_ts_ignore(query);
  moonbit_ts_ignore(tree);
  moonbit_ts_trace("self = %p\n", (void *)self);
  moonbit_ts_trace("self->cursor = %p\n", (void *)self->cursor);
  MoonBitTSQueryMatch *match = (MoonBitTSQueryMatch *)moonbit_make_bytes_sz(
    sizeof(MoonBitTSQueryMatch), 0
  );
  bool has_match = ts_query_cursor_next_match(self->cursor, &match->match);
  moonbit_ts_trace("has_match = %d\n", has_match);
  if (has_match) {
    return match;
  } else {
    moonbit_decref(match);
    return NULL;
  }
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_cursor_remove_match(
  MoonBitTSQueryCursor *self,
  MoonBitTSQuery *query,
  MoonBitTSTree *tree,
  uint32_t match_id
) {
  moonbit_ts_ignore(query);
  moonbit_ts_ignore(tree);
  ts_query_cursor_remove_match(self->cursor, match_id);
}

MOONBIT_FFI_EXPORT
MoonBitTSQueryMatch *
moonbit_ts_query_cursor_next_capture(
  MoonBitTSQueryCursor *self,
  MoonBitTSQuery *query,
  MoonBitTSTree *tree,
  uint32_t *match_id
) {
  moonbit_ts_ignore(query);
  moonbit_ts_ignore(tree);
  MoonBitTSQueryMatch *match = (MoonBitTSQueryMatch *)moonbit_make_bytes_sz(
    sizeof(MoonBitTSQueryMatch), 0
  );
  bool has_match =
    ts_query_cursor_next_capture(self->cursor, &match->match, match_id);
  if (has_match) {
    return match;
  } else {
    moonbit_decref(match);
    return NULL;
  }
}

MOONBIT_FFI_EXPORT
void
moonbit_ts_query_cursor_set_max_start_depth(
  MoonBitTSQueryCursor *self,
  uint32_t max_start_depth
) {
  ts_query_cursor_set_max_start_depth(self->cursor, max_start_depth);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_match_id(MoonBitTSQueryMatch *self) {
  return self->match.id;
}

MOONBIT_FFI_EXPORT
uint16_t
moonbit_ts_query_match_pattern_index(MoonBitTSQueryMatch *self) {
  return self->match.pattern_index;
}

MOONBIT_FFI_EXPORT
uint16_t
moonbit_ts_query_match_capture_count(MoonBitTSQueryMatch *self) {
  return self->match.capture_count;
}

MOONBIT_FFI_EXPORT
MoonBitTSNode *
moonbit_ts_query_match_captures_get_node(
  MoonBitTSQueryMatch *self,
  uint32_t index
) {
  TSNode node = self->match.captures[index].node;
  moonbit_ts_trace("node.id = %p\n", node.id);
  return moonbit_ts_node_new(node);
}

MOONBIT_FFI_EXPORT
uint32_t
moonbit_ts_query_match_captures_get_index(
  MoonBitTSQueryMatch *self,
  uint32_t index
) {
  uint32_t i = self->match.captures[index].index;
  return i;
}

typedef struct MoonBitTSLookaheadIterator {
  TSLookaheadIterator *iterator;
} MoonBitTSLookaheadIterator;

static inline void
moonbit_ts_lookahead_iterator_delete(void *object) {
  MoonBitTSLookaheadIterator *self = (MoonBitTSLookaheadIterator *)object;
  ts_lookahead_iterator_delete(self->iterator);
}

MOONBIT_FFI_EXPORT
MoonBitTSLookaheadIterator *
moonbit_ts_lookahead_iterator_new(TSLanguage *language, TSStateId state) {
  MoonBitTSLookaheadIterator *self =
    (MoonBitTSLookaheadIterator *)moonbit_make_external_object(
      moonbit_ts_lookahead_iterator_delete, sizeof(MoonBitTSLookaheadIterator)
    );
  self->iterator = ts_lookahead_iterator_new(language, state);
  return self;
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_lookahead_iterator_reset_state(
  MoonBitTSLookaheadIterator *self,
  TSStateId state
) {
  return ts_lookahead_iterator_reset_state(self->iterator, state);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_lookahead_iterator_reset(
  MoonBitTSLookaheadIterator *self,
  TSLanguage *language,
  TSStateId state
) {
  return ts_lookahead_iterator_reset(self->iterator, language, state);
}

MOONBIT_FFI_EXPORT
const TSLanguage *
moonbit_ts_lookahead_iterator_language(MoonBitTSLookaheadIterator *self) {
  return ts_lookahead_iterator_language(self->iterator);
}

MOONBIT_FFI_EXPORT
int32_t
moonbit_ts_lookahead_iterator_next(MoonBitTSLookaheadIterator *self) {
  return ts_lookahead_iterator_next(self->iterator);
}

MOONBIT_FFI_EXPORT
TSSymbol
moonbit_ts_lookahead_iterator_current_symbol(
  const MoonBitTSLookaheadIterator *self
) {
  return ts_lookahead_iterator_current_symbol(self->iterator);
}

MOONBIT_FFI_EXPORT
const char *
moonbit_ts_lookahead_iterator_current_symbol_name(
  const MoonBitTSLookaheadIterator *self
) {
  return ts_lookahead_iterator_current_symbol_name(self->iterator);
}
