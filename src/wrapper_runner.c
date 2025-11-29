// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2025 midischwarz12

#define _GNU_SOURCE

#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define MARKER "WRAPCFG1"
#define MARKER_LEN 7

struct vec {
  char **data;
  size_t len;
  size_t cap;
};

static int vec_push(struct vec *v, char *s) {
  if (v->len + 1 >= v->cap) {
    size_t new_cap = v->cap ? v->cap * 2 : 4;
    char **tmp = realloc(v->data, new_cap * sizeof(char *));
    if (!tmp)
      return -1;
    v->data = tmp;
    v->cap = new_cap;
  }
  v->data[v->len++] = s;
  return 0;
}

static void die(const char *msg) {
  perror(msg);
  _exit(errno ? errno : 111);
}

static char *dup_or_die(const char *s) {
  char *d = strdup(s);
  if (!d)
    die("strdup");
  return d;
}

static char *read_self_path(const char *argv0) {
  static char path[PATH_MAX];
  ssize_t r = readlink("/proc/self/exe", path, sizeof(path) - 1);
  if (r >= 0) {
    path[r] = '\0';
    return path;
  }
  // Fallback to argv[0]; may be relative.
  strncpy(path, argv0, sizeof(path) - 1);
  path[sizeof(path) - 1] = '\0';
  return path;
}

static void apply_prefix(const char *env, const char *sep, const char *val) {
  const char *current = getenv(env);
  size_t len = strlen(val) + (current ? strlen(current) + strlen(sep) : 0) + 1;
  char *buf = malloc(len);
  if (!buf)
    die("malloc");
  if (current && *current)
    snprintf(buf, len, "%s%s%s", val, sep, current);
  else
    snprintf(buf, len, "%s", val);
  setenv(env, buf, 1);
  free(buf);
}

static void apply_suffix(const char *env, const char *sep, const char *val) {
  const char *current = getenv(env);
  size_t len = strlen(val) + (current ? strlen(current) + strlen(sep) : 0) + 1;
  char *buf = malloc(len);
  if (!buf)
    die("malloc");
  if (current && *current)
    snprintf(buf, len, "%s%s%s", current, sep, val);
  else
    snprintf(buf, len, "%s", val);
  setenv(env, buf, 1);
  free(buf);
}

int main(int argc, char **argv) {
  const char *self = read_self_path(argv[0]);

  FILE *f = fopen(self, "rb");
  if (!f)
    die("open self");

  struct stat st;
  if (fstat(fileno(f), &st) != 0)
    die("stat self");

  if ((size_t)st.st_size < MARKER_LEN + sizeof(uint32_t)) {
    fprintf(stderr, "wrapper: missing embedded config\n");
    return 111;
  }

  if (fseek(f, st.st_size - 4, SEEK_SET) != 0)
    die("fseek len");

  uint32_t cfg_len = 0;
  if (fread(&cfg_len, sizeof(uint32_t), 1, f) != 1)
    die("read len");

  long marker_pos = st.st_size - 4 - cfg_len - MARKER_LEN;
  if (marker_pos < 0) {
    fprintf(stderr, "wrapper: bad embedded config length\n");
    return 111;
  }

  if (fseek(f, marker_pos, SEEK_SET) != 0)
    die("fseek marker");

  char marker[MARKER_LEN];
  if (fread(marker, 1, MARKER_LEN, f) != MARKER_LEN)
    die("read marker");

  if (memcmp(marker, MARKER, MARKER_LEN) != 0) {
    fprintf(stderr, "wrapper: marker mismatch\n");
    return 111;
  }

  char *cfg = malloc(cfg_len + 1);
  if (!cfg)
    die("malloc cfg");

  if (fread(cfg, 1, cfg_len, f) != cfg_len)
    die("read cfg");
  cfg[cfg_len] = '\0';
  fclose(f);

  char *exec_path = NULL;
  char *argv0 = NULL;
  char *chdir_path = NULL;

  struct vec pre_runs = {0}, prefix_args = {0}, suffix_args = {0};
  struct vec sets = {0}, set_defaults = {0}, unsets = {0};
  struct vec prefixes = {0}, suffixes = {0};

  char *saveptr = NULL;
  for (char *line = strtok_r(cfg, "\n", &saveptr); line; line = strtok_r(NULL, "\n", &saveptr)) {
    if (*line == '\0')
      continue;

    if (strncmp(line, "exec=", 5) == 0) {
      exec_path = line + 5;
      continue;
    }
    if (strncmp(line, "argv0=", 6) == 0) {
      argv0 = line + 6;
      continue;
    }
    if (strncmp(line, "chdir=", 6) == 0) {
      chdir_path = line + 6;
      continue;
    }
    if (strncmp(line, "preRun=", 7) == 0) {
      vec_push(&pre_runs, line + 7);
      continue;
    }
    if (strncmp(line, "prefixArg=", 10) == 0) {
      vec_push(&prefix_args, line + 10);
      continue;
    }
    if (strncmp(line, "suffixArg=", 10) == 0) {
      vec_push(&suffix_args, line + 10);
      continue;
    }
    if (strncmp(line, "set=", 4) == 0) {
      vec_push(&sets, line + 4);
      continue;
    }
    if (strncmp(line, "setDefault=", 11) == 0) {
      vec_push(&set_defaults, line + 11);
      continue;
    }
    if (strncmp(line, "unset=", 6) == 0) {
      vec_push(&unsets, line + 6);
      continue;
    }
    if (strncmp(line, "prefix=", 7) == 0) {
      vec_push(&prefixes, line + 7);
      continue;
    }
    if (strncmp(line, "suffix=", 7) == 0) {
      vec_push(&suffixes, line + 7);
      continue;
    }
  }

  if (!exec_path) {
    fprintf(stderr, "wrapper: missing exec in config\n");
    return 111;
  }

  if (chdir_path && *chdir_path) {
    if (chdir(chdir_path) != 0)
      die("chdir");
  }

  for (size_t i = 0; i < pre_runs.len; i++) {
    int rc = system(pre_runs.data[i]);
    if (rc != 0) {
      fprintf(stderr, "wrapper: preRun command failed: %s (rc=%d)\n", pre_runs.data[i], rc);
      return rc;
    }
  }

  for (size_t i = 0; i < sets.len; i++) {
    char *eq = strchr(sets.data[i], '=');
    if (!eq) continue;
    *eq = '\0';
    setenv(sets.data[i], eq + 1, 1);
    *eq = '=';
  }

  for (size_t i = 0; i < set_defaults.len; i++) {
    char *eq = strchr(set_defaults.data[i], '=');
    if (!eq) continue;
    *eq = '\0';
    if (!getenv(set_defaults.data[i]))
      setenv(set_defaults.data[i], eq + 1, 1);
    *eq = '=';
  }

  for (size_t i = 0; i < unsets.len; i++) {
    unsetenv(unsets.data[i]);
  }

  for (size_t i = 0; i < prefixes.len; i++) {
    char *first = strchr(prefixes.data[i], '|');
    if (!first) continue;
    *first = '\0';
    char *second = strchr(first + 1, '|');
    if (!second) { *first = '|'; continue; }
    *second = '\0';
    apply_prefix(prefixes.data[i], first + 1, second + 1);
    *second = '|';
    *first = '|';
  }

  for (size_t i = 0; i < suffixes.len; i++) {
    char *first = strchr(suffixes.data[i], '|');
    if (!first) continue;
    *first = '\0';
    char *second = strchr(first + 1, '|');
    if (!second) { *first = '|'; continue; }
    *second = '\0';
    apply_suffix(suffixes.data[i], first + 1, second + 1);
    *second = '|';
    *first = '|';
  }

  struct vec argvv = {0};
  vec_push(&argvv, argv0 && *argv0 ? argv0 : exec_path);
  for (size_t i = 0; i < prefix_args.len; i++) vec_push(&argvv, prefix_args.data[i]);
  for (int i = 1; i < argc; i++) vec_push(&argvv, argv[i]);
  for (size_t i = 0; i < suffix_args.len; i++) vec_push(&argvv, suffix_args.data[i]);
  vec_push(&argvv, NULL);

  execv(exec_path, argvv.data);
  die("execv");
  return 127;
}
