import { beforeEach, describe, expect, it, vi } from 'vitest'

const getMock = vi.fn()
const patchMock = vi.fn()
const refreshMock = vi.fn()
vi.mock('./apiClient', () => ({
  omiApi: {
    get: (...args: unknown[]) => getMock(...args),
    patch: (...args: unknown[]) => patchMock(...args)
  }
}))
vi.mock('./ptt/userVocabulary', () => ({ refreshUserVocabulary: () => refreshMock() }))

import {
  VOCABULARY_LIMIT,
  VOCABULARY_TERM_MAX_CHARS,
  addVocabularyTerms,
  fetchTranscriptionVocabulary,
  parseVocabularyInput,
  removeVocabularyTerm,
  saveTranscriptionVocabulary
} from './transcriptionVocabulary'

beforeEach(() => {
  getMock.mockReset()
  patchMock.mockReset()
  refreshMock.mockReset()
})

describe('parseVocabularyInput', () => {
  it('splits on commas, trims, collapses inner whitespace and drops empties', () => {
    expect(parseVocabularyInput('  Omi ,Kubernetes,, Based   Hardware ,')).toEqual([
      'Omi',
      'Kubernetes',
      'Based Hardware'
    ])
  })
  it('clips an oversized term', () => {
    const long = 'x'.repeat(VOCABULARY_TERM_MAX_CHARS + 20)
    expect(parseVocabularyInput(long)[0]).toHaveLength(VOCABULARY_TERM_MAX_CHARS)
  })
})

describe('addVocabularyTerms', () => {
  it('appends new terms preserving the user’s casing', () => {
    const r = addVocabularyTerms(['Omi'], 'Deepgram, Typesense')
    expect(r.terms).toEqual(['Omi', 'Deepgram', 'Typesense'])
    expect(r.added).toEqual(['Deepgram', 'Typesense'])
    expect(r.duplicates).toEqual([])
    expect(r.overflow).toEqual([])
  })

  it('dedupes case-insensitively against the list and within one submission (Mac rule)', () => {
    const r = addVocabularyTerms(['Omi'], 'omi, OMI, Nik, nik')
    expect(r.terms).toEqual(['Omi', 'Nik'])
    expect(r.duplicates).toEqual(['omi', 'OMI', 'nik'])
  })

  it('refuses to exceed the backend cap of 100 and reports the overflow', () => {
    const full = Array.from({ length: VOCABULARY_LIMIT - 1 }, (_, i) => `t${i}`)
    const r = addVocabularyTerms(full, 'fits, dropped')
    expect(r.terms).toHaveLength(VOCABULARY_LIMIT)
    expect(r.added).toEqual(['fits'])
    expect(r.overflow).toEqual(['dropped'])
  })

  it('is a no-op for blank input', () => {
    const r = addVocabularyTerms(['Omi'], '   ,  ')
    expect(r.terms).toEqual(['Omi'])
    expect(r.added).toEqual([])
  })
})

describe('removeVocabularyTerm', () => {
  it('removes by exact stored spelling only', () => {
    expect(removeVocabularyTerm(['Omi', 'omi'], 'omi')).toEqual(['Omi'])
  })
})

describe('fetchTranscriptionVocabulary', () => {
  it('reads the vocabulary field from /v1/users/transcription-preferences', async () => {
    getMock.mockResolvedValue({
      data: { single_language_mode: false, vocabulary: ['Omi', ' ', 7] }
    })
    expect(await fetchTranscriptionVocabulary()).toEqual(['Omi'])
    expect(getMock).toHaveBeenCalledWith('/v1/users/transcription-preferences')
  })
  it('treats a missing field as an empty list, not an error', async () => {
    getMock.mockResolvedValue({ data: { single_language_mode: true } })
    expect(await fetchTranscriptionVocabulary()).toEqual([])
  })
})

describe('saveTranscriptionVocabulary', () => {
  it('PATCHes the whole list as `vocabulary` and warms the PTT keyword cache', async () => {
    patchMock.mockResolvedValue({ data: { status: 'ok' } })
    await saveTranscriptionVocabulary(['Omi', 'Deepgram'])
    expect(patchMock).toHaveBeenCalledWith('/v1/users/transcription-preferences', {
      vocabulary: ['Omi', 'Deepgram']
    })
    expect(refreshMock).toHaveBeenCalledTimes(1)
  })

  it('does not touch the PTT cache when the PATCH is rejected', async () => {
    patchMock.mockRejectedValue(new Error('500'))
    await expect(saveTranscriptionVocabulary(['Omi'])).rejects.toThrow('500')
    expect(refreshMock).not.toHaveBeenCalled()
  })
})
