import { ethers } from 'ethers';
import { loadEnv } from './lib/config.js';
import { evaluatePolicy, normalizeAddresses } from './lib/policy.js';

async function main() {
  const env = loadEnv();
  const provider = new ethers.JsonRpcProvider(env.RPC_URL, env.CHAIN_ID);
  
  // 冻结合约地址（来自 Role A 交付）
  const FREEZE_CONTRACT = '0x3168a2307a3c272ea6CE2ab0EF1733CA493aa719';
  
  // 测试目标：使用 Owner 2 地址（Role A 文档提到它可能被用于测试冻结，或者我们假设它被冻结）
  // 注意：如果 Owner 2 实际上没被冻结，这个脚本会返回 OK。
  // 为了测试 REJECT，我们需要确认一个真正被冻结的地址。
  // 这里我们先测试机制是否跑通（即是否真的去查了链）。
  const targetAddress = '0xb89Ffb647Bc1D12eDcf7b0C13753300e17F2d6e9'; // Owner 2

  console.log('--- 测试链上冻结检查 ---');
  console.log('RPC:', env.RPC_URL);
  console.log('Freeze Contract:', FREEZE_CONTRACT);
  console.log('Checking Target:', targetAddress);

  const policy = {
    allowlist: [targetAddress], // 故意把它加到白名单，看是否会被冻结拦截
    maxAmount: ethers.parseEther('100'),
  };

  const decision = await evaluatePolicy({
    policy,
    recipient: targetAddress,
    amount: ethers.parseEther('1'),
    provider,
    freezeContractAddress: FREEZE_CONTRACT
  });

  if (decision.ok) {
    console.log('[PASS] 地址未被冻结，允许支付。');
    console.log('(注：如果该地址本应被冻结但通过了，请检查合约状态)');
  } else {
    console.log('[REJECT] 拦截成功！');
    console.log('Code:', decision.code);
    console.log('Message:', decision.message);
  }
}

main().catch(console.error);
