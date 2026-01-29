import { ethers } from 'ethers';
import { GokiteAASDK } from 'gokite-aa-sdk';
import { erc20Interface } from './erc20.js';

export async function probeKiteAASdk() {
  // For debugging only: help quickly understand module exports on the judge machine
  const mod: any = await import('gokite-aa-sdk');
  const keys = Object.keys(mod).sort();
  return { keys };
}

export async function sendErc20ViaAA(args: {
  rpcUrl: string;
  bundlerUrl: string;
  ownerWallet: ethers.Wallet;
  token: string;
  to: string;
  amount: bigint;
  paymasterAddress?: string;
}): Promise<{
  userOpHash: string;
  txHash: string | null;
  status: 'success' | 'failed' | 'pending';
  reason?: string;
}> {
  try {
    console.log('[AA] 初始化 GokiteAASDK...');
    const sdk = new GokiteAASDK('kite_testnet', args.rpcUrl, args.bundlerUrl);

    // 步骤 1: 获取 owner EOA 地址
    const owner = await args.ownerWallet.getAddress();
    console.log('[AA] Owner EOA:', owner);

    // 步骤 2: 获取 AA 钱包地址
    const accountAddress = sdk.getAccountAddress(owner);
    console.log('[AA] AA Account Address:', accountAddress);

    // 步骤 3: 编码 ERC-20 transfer callData
    const iface = erc20Interface();
    const callData = iface.encodeFunctionData('transfer', [args.to, args.amount]);
    console.log('[AA] CallData:', callData);

    // 步骤 4: 创建签名函数
    const signFunction = async (userOpHash: string): Promise<string> => {
      console.log('[AA] 签署 UserOp 哈希:', userOpHash);
      const signature = await args.ownerWallet.signMessage(ethers.getBytes(userOpHash));
      console.log('[AA] 签名成功');
      return signature;
    };

    // 步骤 5: 发送 UserOperation（异步，不等待）
    console.log('[AA] 发送 UserOperation...');
    const userOpHash = await sdk.sendUserOperation(
      owner,
      {
        target: args.token,
        value: 0n,
        callData
      },
      signFunction,
      undefined, // salt
      args.paymasterAddress
    );

    console.log('[AA] UserOpHash:', userOpHash);

    // 步骤 6: 轮询 UserOperation 状态（最多等待 120 秒）
    console.log('[AA] 轮询状态...');
    let status = await sdk.pollUserOperationStatus(userOpHash);
    let attempts = 0;
    const maxAttempts = 120; // 最多 2 分钟

    while (status?.status === 'pending' && attempts < maxAttempts) {
      console.log(`[AA] 轮询中... (${attempts + 1}/${maxAttempts})`);
      await new Promise(resolve => setTimeout(resolve, 1000));
      status = await sdk.pollUserOperationStatus(userOpHash);
      attempts++;
    }

    // 步骤 7: 解析结果
    const txHash = status?.transactionHash || null;
    const finalStatus = (status?.status || 'failed') as 'success' | 'failed' | 'pending';
    const reason = status?.reason || undefined;

    console.log('[AA] 最终结果:', {
      userOpHash,
      txHash,
      status: finalStatus,
      reason,
      pollAttempts: attempts
    });

    return {
      userOpHash,
      txHash,
      status: finalStatus,
      reason
    };
  } catch (error) {
    console.error('[AA] 错误:', error);
    throw error;
  }
}

