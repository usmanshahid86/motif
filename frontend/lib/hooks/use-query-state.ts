import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

export function useQueryState(key: string, defaultValue?: string) {
  const [currentQueryValue, setCurrentQueryValue] = useState(
    defaultValue || ""
  );

  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const currentTabParam = searchParams.get(key);

  const createQueryString = useCallback(
    (name: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());

      params.set(name, value);

      return params.toString();
    },
    [searchParams]
  );

  const setQueryValue = useCallback(
    (newQueryValue: string) => {
      setCurrentQueryValue(newQueryValue);
      router.replace(`${pathname}?${createQueryString(key, newQueryValue)}`, {
        scroll: false,
      });
    },
    [key, pathname, createQueryString]
  );

  function useHandleExternalTabChange() {
    useEffect(() => {
      if (
        !currentTabParam ||
        currentQueryValue === currentTabParam // note: prevent unnecessary updates
      )
        return;

      setQueryValue(currentTabParam);
    }, [currentTabParam]);
  }

  useHandleExternalTabChange();

  return {
    currentQueryValue,
    setQueryValue,
  };
}
