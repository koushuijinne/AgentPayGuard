import { ethers } from 'ethers';

export type Policy = {
  allowlist?: string[];
  maxAmount?: bigint;
  dailyLimit?: bigint;
};

export type PolicyDecision =
  | { ok: true }
  | { ok: false; code: 'NOT_IN_ALLOWLIST' | 'AMOUNT_EXCEEDS_MAX' | 'DAILY_LIMIT_EXCEEDED' | 'RECIPIENT_FROZEN'; message: string };

export function normalizeAddresses(addrs: string[]): string[] {
  return addrs
    .map((a) => a.trim())
    .filter(Boolean)
    .map((a) => ethers.getAddress(a));
}

// SimpleFreeze contract ABI (minimal)
const FREEZE_ABI = ['function isFrozen(address account) view returns (bool)'];

export async function evaluatePolicy(args: {
  policy: Policy;
  recipient: string;
  amount: bigint;
  spentToday?: bigint; // in token units
  provider?: ethers.Provider; // Optional: needed for on-chain freeze check
  freezeContractAddress?: string; // Optional: address of the freeze contract
}): Promise<PolicyDecision> {
  const recipient = ethers.getAddress(args.recipient);
  const { policy, amount, provider, freezeContractAddress } = args;

  // 1. Check Allowlist
  if (policy.allowlist && policy.allowlist.length > 0) {
    const ok = policy.allowlist.some((a) => ethers.getAddress(a) === recipient);
    if (!ok) {
      return {
        ok: false,
        code: 'NOT_IN_ALLOWLIST',
        message: `收款地址不在白名单：${recipient}`
      };
    }
  }

  // 2. Check On-chain Freeze Status (Strong Consistency)
  if (provider && freezeContractAddress) {
    try {
      const freezeContract = new ethers.Contract(freezeContractAddress, FREEZE_ABI, provider);
      const isFrozen: boolean = await freezeContract.isFrozen(recipient);
      
      if (isFrozen) {
        return {
          ok: false,
          code: 'RECIPIENT_FROZEN',
          message: `收款地址已被多签冻结：${recipient}`
        };
      }
    } catch (error: any) {
      // In Strong Consistency mode, we fail if we can't verify status
      console.error('[Policy] Failed to check freeze status:', error);
      throw new Error(`策略校验失败：无法验证链上冻结状态 (${error.message})`);
    }
  }

  // 3. Check Max Amount
  if (policy.maxAmount !== undefined && amount > policy.maxAmount) {
    return {
      ok: false,
      code: 'AMOUNT_EXCEEDS_MAX',
      message: `单笔金额超过上限：amount=${amount.toString()} max=${policy.maxAmount.toString()}`
    };
  }

  if (policy.dailyLimit !== undefined) {
    const spent = args.spentToday ?? 0n;
    if (spent + amount > policy.dailyLimit) {
      return {
        ok: false,
        code: 'DAILY_LIMIT_EXCEEDED',
        message: `日累计超过限额：spent=${spent.toString()} + amount=${amount.toString()} > dailyLimit=${policy.dailyLimit.toString()}`
      };
    }
  }

  return { ok: true };
}

