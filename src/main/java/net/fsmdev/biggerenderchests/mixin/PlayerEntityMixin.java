package net.fsmdev.biggerenderchests.mixin;

import com.mojang.authlib.GameProfile;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.inventory.EnderChestInventory;
import net.minecraft.item.ItemStack;
import net.minecraft.util.collection.DefaultedList;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(PlayerEntity.class)
public abstract class PlayerEntityMixin {
    @Shadow public abstract EnderChestInventory getEnderChestInventory();

    @Inject(method="<init>", at = @At(value="RETURN"))
    private void resizableEnderChest(final World w, final GameProfile gp, final CallbackInfo ci) {
        SimpleInventoryMixin enderChestInventory = (SimpleInventoryMixin) getEnderChestInventory();
        enderChestInventory.setSize(54);
        enderChestInventory.setStacks(DefaultedList.ofSize(54, ItemStack.EMPTY));
    }
}
