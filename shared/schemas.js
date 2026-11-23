import { z } from 'zod'

const id = z.string().min(1).max(64)
const ts = z.number().int().nonnegative()
const nullableTs = ts.nullable().optional().default(null)
const currency = z.string().regex(/^[A-Z]{3}$/)

export const transactionSchema = z.object({
  id,
  type: z.enum(['expense', 'credit']),
  amount: z.number().positive().max(1e12),
  currency,
  amountInBase: z.number().nonnegative().max(1e13),
  categoryId: id,
  note: z.string().max(500).default(''),
  date: ts,
  createdAt: ts,
  updatedAt: ts,
  deletedAt: nullableTs,
})

export const categorySchema = z.object({
  id,
  name: z.string().trim().min(1).max(40),
  emoji: z.string().min(1).max(16),
  color: z.string().regex(/^#[0-9a-fA-F]{6}$/).optional(),
  order: z.number().int(),
  updatedAt: ts,
  deletedAt: nullableTs,
})

export const budgetSchema = z.object({
  id,
  categoryId: id.nullable(),
  amount: z.number().nonnegative().max(1e13),
  updatedAt: ts,
  deletedAt: nullableTs,
})

export const settingsSchema = z.object({
  id: z.literal('app'),
  baseCurrency: currency,
  cycleStartDay: z.number().int().min(1).max(28),
  rateOverrides: z.record(currency, z.number().positive()).default({}),
  updatedAt: ts,
})

export const COLLECTIONS = {
  transactions: transactionSchema,
  categories: categorySchema,
  budgets: budgetSchema,
  settings: settingsSchema,
}

export const backupSchema = z.object({
  app: z.literal('expy'),
  version: z.number().int(),
  exportedAt: ts,
  transactions: z.array(transactionSchema),
  categories: z.array(categorySchema),
  budgets: z.array(budgetSchema).default([]),
  settings: settingsSchema.optional(),
})

export const quickAddSchema = z.object({
  amount: z.coerce.number().positive().max(1e12),
  category: z.string().max(60).optional().default(''),
  type: z
    .string()
    .optional()
    .transform((t) => (String(t || '').toLowerCase().startsWith('c') ? 'credit' : 'expense')),
  note: z.string().max(500).optional().default(''),
  date: z.union([z.string(), z.number()]).optional(),
  currency: currency.optional(),
})
