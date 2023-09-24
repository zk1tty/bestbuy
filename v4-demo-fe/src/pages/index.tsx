import React, { useState, useEffect } from 'react';
import { Inter } from 'next/font/google'
import abi from "../abi/SwapTest.json"
import { ethers } from "ethers"
import Button from '@mui/material/Button';
import { Box } from '@mui/material/Box';

const inter = Inter({ subsets: ['latin'] })

const styles = {}

export default function Home() {

  const [ethereum, setEthereum] = useState(undefined);
  const [connectedAccount, setConnectedAccount] = useState(undefined);
  const [swapInput, setSwapInput] = useState(undefined);

  const SWAP_TEST_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  const contractABI = abi.abi;
  
  const connectAccount = async () => {
    if (!ethereum) {
      alert('MetaMask is required to connect an account');
      return;
    }
  
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    handleAccounts(accounts);
  };

  const handleAccounts = (accounts) => {
    if (accounts.length > 0) {
      const account = accounts[0];
      console.log('We have an authorized account: ', account);
      setConnectedAccount(account);
    } else {
      console.log("No authorized accounts yet")
    }
  };
  
  const getConnectedAccount = async () => {
    console.log("window.ethereum", window.ethereum);
    if (window.ethereum) {
      setEthereum(window.ethereum);
    }
    console.log("ethereum:", ethereum);
  
    if (ethereum) {
      const accounts = await ethereum.request({ method: 'eth_accounts' });
      handleAccounts(accounts);
    }
    return;
  };

  const getContract = async () => {
    if (ethereum && connectedAccount) {
      const provider = new ethers.BrowserProvider(ethereum);
      const signer = provider.getSigner();
      const swapTestContract = new ethers.Contract(SWAP_TEST_ADDRESS, contractABI, signer);

      console.log('swapTestContract:', swapTestContract);
      await swapTestContract.callSwapHooks();
      // console.log('Set up is done');
    }
  }
 
  useEffect(() => { getConnectedAccount() }, []);
  
  if (!ethereum) {
    return <p>Please install MetaMask to connect to this site</p>
  }

  if (!connectedAccount) {
    return (
    <div className="background-color:black">
      <Box>
        <Button 
          onClick={connectAccount} >
            Connect MetaMask Wallet
        </Button>  
      </Box>
      <Box>
        <Button 
          onClick={getContract} >
            Swap
        </Button>
      </Box>
    </div>
    );
  }

  return <p>Connected Account: {connectedAccount}</p>
}
