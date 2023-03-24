class Solution {
public:
    int minimizeSum(vector<int>& nums) {
        int n = nums.size();
        if(n < 4) {
            return 0;
        }
        sort(nums.begin(), nums.end());
        vector<int> candidate = {
            nums[n-3] - nums[0],
            nums[n-2] - nums[1],
            nums[n-1] - nums[2],
        };
        return *min_element(candidate.begin(), candidate.end());
    }
};