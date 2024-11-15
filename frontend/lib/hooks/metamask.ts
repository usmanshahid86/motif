import { useToast } from "@/hooks/use-toast";
import { useSDK } from "@metamask/sdk-react";
import { useCallback, useEffect, useState } from "react";

function useMetamaskAddress() {
  const metamask = useSDK();
  const { toast } = useToast();

  const [account, setAccount] = useState(metamask.account);

  const connect = useCallback(() => {
    try {
      console.log(metamask.extensionActive, metamask.sdk);
      if (!metamask.extensionActive || !metamask.sdk) {
        toast({
          title: "Metamask not detected",
          description: "Please install Metamask to continue to donate.",
        });

        return;
      }

      metamask.sdk?.connect();
    } catch (_error) {
      console.error(_error);
      toast({
        variant: "destructive",
        title: "Unexpected Error",
        description:
          "An unexpected error occurred with Metamask, please try to refresh the page.",
      });
    }
  }, [metamask.sdk, metamask.extensionActive]);

  const disconnect = useCallback(() => {
    metamask.sdk?.disconnect();

    toast({
      title: "Disconnected Metamask",
      description: "Metamask was successfully disconnected.",
    });
  }, [metamask.sdk]);

  useEffect(() => {
    setAccount(metamask.account);
  }, [metamask.account]);

  return {
    account,
    connect,
    disconnect,
  };
}

export { useMetamaskAddress };
